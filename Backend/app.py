


import os
from flask import Flask, request, jsonify
from groq import Groq
from datetime import datetime, timedelta
import uuid
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_community.document_loaders import PyMuPDFLoader
from markdown import markdown
import re
from tempfile import NamedTemporaryFile

# Flask app
app = Flask(__name__)


app.secret_key = 'supersecretkey'  # Retain for session management if needed

app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB limit for uploads

# Store extracted PDF content globally
pdf_content_store = {}

GOOGLE_API_KEY = "AIzaSyCSq35o-1vLYe3bKjKRoGNezTJNRmDMEx0"
os.environ["GOOGLE_API_KEY"] = GOOGLE_API_KEY

# Initialize the language model
llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash", temperature=0.5)

def preprocess_document(text):
    # Extract main content from Introduction to References
    intro_match = re.search(r'\bIntroduction\b', text, re.IGNORECASE)
    ref_match = re.search(r'\bReferences\b', text, re.IGNORECASE)

    if intro_match and ref_match:
        start = intro_match.start()
        end = ref_match.end()
        return text[start:end]
    elif intro_match:
        start = intro_match.start()
        return text[start:]
    elif ref_match:
        end = ref_match.end()
        return text[:end]
    else:
        return text

@app.route('/rpr', methods=['GET', 'POST'])
def upload_pdf():
    if request.method == 'POST':
        user_file = request.files.get("file")
        
        if user_file:
            with NamedTemporaryFile(delete=False) as temp_file:
                user_file.save(temp_file.name)
                loader = PyMuPDFLoader(temp_file.name)
                data = loader.load()

            # Extract content and store it globally
            document_text = " ".join([preprocess_document(doc.page_content) for doc in data])
            pdf_content_store['latest'] = document_text  # Store latest PDF content

            return jsonify({"message": "PDF content uploaded successfully."}), 200

        return jsonify({"error": "Please select a PDF file."}), 400

    return render_template("index.html")  # Render index.html for GET requests

@app.route('/chat', methods=['POST'])
def chat():
    user_message = request.json.get('message')  # Get user message
    language = request.json.get('language', 'en')  # Get language preference, default to English (en)

    if 'latest' not in pdf_content_store:
        return jsonify({"response": "No PDF content available. Please upload a PDF first."})

    document_text = pdf_content_store['latest']

    # Modify prompt based on language preference
    if language == 'ur':  # If the user prefers Urdu
        prompt = (
            f"As a proficient legal assistant specializing in Pakistani legal documents and case files, please respond in Urdu when necessary. "
            f"Here is the document content: {document_text}\n"
            f"User asked: {user_message}\n"
            f"Answer in Urdu:"
        )
    else:  # Default to English
        prompt = (
            f"As a proficient legal assistant specializing in legal documents and case files, please respond in English when necessary. "
            f"Here is the document content: {document_text}\n"
            f"User asked: {user_message}\n"
            f"Answer in English:"
        )

    # Get the response from the language model
    response = llm.predict(prompt)

    if not response:
        return jsonify({"response": "I couldn't find an answer to that."})

    return jsonify({"response": response})

os.environ["GROQ_API_KEY"] = "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"
# Initialize the Groq client
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

# Global dictionary to hold active conversations
conversations = {}

# Core questions for legal guidance
core_questions = [
    "Where did the incident occur?",
    "What is the name of the person involved?",
    "When did this incident happen?",
    "Can you provide a brief description of what happened?"
]

# Validation functions
def validate_location(location):
    """Validate and enhance location input."""
    vague_terms = ["my home", "nearby", "here", "my office"]
    if location.lower() in vague_terms:
        return False, "Please specify the location, such as the city or neighborhood."
    return True, location

def validate_date(date_input):
    """Validate and convert date input."""
    if date_input.lower() == "yesterday":
        date = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
        return True, date
    elif date_input.lower() in ["today", "now"]:
        date = datetime.now().strftime('%Y-%m-%d')
        return True, date
    try:
        date = datetime.strptime(date_input, "%Y-%m-%d").strftime('%Y-%m-%d')
        return True, date
    except ValueError:
        return False, "Please provide a valid date in YYYY-MM-DD format."

def validate_name(name):
    """Validate the name input."""
    if len(name.split()) < 2:  # Expecting at least a first and last name
        return False, "Please provide the full name of the person involved."
    return True, name

@app.route('/start-conversation', methods=['POST'])
def start_conversation():
    """Start a new conversation and detect the user's intent."""
    data = request.json
    user_message = data.get("message")

    if not user_message:
        return jsonify({"error": "Message is required"}), 400

    # Normalize the input message for easier greeting detection
    normalized_message = user_message.strip().lower()

    # Check if the message is a greeting
    greetings = ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"]
    if any(greeting in normalized_message for greeting in greetings):
        return jsonify({
            "message": "Hi! How can I help you with legal advice today?",
            "current_index": 0
        }), 200

    # If it's not a greeting, generate dynamic questions based on the user's case message
    prompt = (
        f"You are a legal assistant specializing in Pakistani law. "
        f"User has a legal issue: '{user_message}'. Please generate up to 10 relevant questions to understand the situation in detail."
    )
    
    try:
        # Get questions from Gemini (or any LLM you're using)
        response = llm.predict(prompt)
        questions = response.split('\n')  # Assuming Gemini separates questions with newlines

        # Limit to 10 questions
        questions = [q for q in questions if q.strip()]  # Remove empty lines
        questions = questions[:10]

        # Start the conversation
        conversation_id = str(uuid.uuid4())
        conversations[conversation_id] = {
            "case_details": {"query": user_message},
            "questions": questions,
            "current_index": 0
        }

        return jsonify({
            "conversation_id": conversation_id,
            "message": questions[0] if questions else "Please provide more details about your case.",
            "current_index": 0
        }), 200
    except Exception as e:
        return jsonify({"error": f"Error generating questions: {str(e)}"}), 500


@app.route('/answer-question', methods=['POST'])
def answer_question():
    """Ask the next dynamic question or validate the user's response."""
    data = request.json
    conversation_id = data.get("conversation_id")
    answer = data.get("answer")
    current_index_client = data.get("current_index")

    if not conversation_id or not answer or current_index_client is None:
        return jsonify({"error": "conversation_id, answer, and current_index are required"}), 400

    # Retrieve conversation state
    conversation = conversations.get(conversation_id)
    if not conversation:
        return jsonify({"error": "Invalid conversation_id. Please start a new conversation."}), 400

    case_details = conversation["case_details"]
    current_index = conversation["current_index"]
    questions = conversation["questions"]

    # Ensure the server-side index matches the client's
    if current_index_client != current_index:
        return jsonify({
            "error": "Question progression mismatch. Please retry.",
            "expected_index": current_index
        }), 400

    # Store the answer in the case details
    case_details[f"answer_{current_index}"] = answer

    # Increment the index for the next question
    current_index += 1
    conversation["case_details"] = case_details
    conversation["current_index"] = current_index

    # If all questions have been answered, generate the final response
    if current_index >= len(questions):
        return jsonify({
            "message": "Case data gathered. Generating Legal Advice...",
            "current_index": None
        }), 200

    # Ask the next question
    next_question = questions[current_index]
    return jsonify({"message": next_question, "current_index": current_index}), 200

@app.route('/generate-response', methods=['POST'])
def generate_response():
    """Generate the final response using the collected case details."""
    data = request.json
    conversation_id = data.get("conversation_id")

    if not conversation_id:
        return jsonify({"error": "conversation_id is required"}), 400

    # Retrieve conversation state
    conversation = conversations.get(conversation_id)
    if not conversation:
        return jsonify({"error": "Invalid conversation_id. Please start a new conversation."}), 400


    case_details = conversation["case_details"]
    questions = conversation["questions"]

    # Summarize the case based on the collected answers
    case_summary = "\n".join([f"Question {i+1}: {questions[i]}\nAnswer: {case_details.get(f'answer_{i}', 'Not provided')}"
                             for i in range(len(questions))])


    role_context = (
        "You are a seasoned legal expert specializing in Pakistani law and justice, "
        "with over 30 years of experience. You have an in-depth understanding of the Pakistan Penal Code, "
        "along with other significant legal frameworks, landmark rulings, and their implications. "
        "Your task is to assist legal professionals such as lawyers and judges by providing precise, actionable legal advice "
        "and guiding them through the legal processes. When responding, you should focus on understanding the user's legal issue, "
        "offering relevant advice, explaining the applicable laws, and suggesting the appropriate legal steps. "
        "You will also provide any relevant legal references, rulings, and case law that can aid in understanding the situation.\n\n"
        "After providing your legal advice and response, if the user mentions a city for lodging an FIR, "
        "you should provide the following police station details as the final part of your response, without additional context or explanations:\n"
        "1. Name of a police station in the city,\n"
        "2. The address of the police station,\n"
        "Do not provide additional information beyond the police station details. Additionally, at the end of the response, "
    )


    # Generate final response using Llama 3
    llm_input = f"{role_context}\n\nCase Summary:\n{case_summary}"
    try:
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": role_context},
                {"role": "user", "content": llm_input},
            ],
            model="llama3-8b-8192",
        )
        response = chat_completion.choices[0].message.content
        return jsonify({"response": response}), 200
    except Exception as e:
        return jsonify({"error": f"Error generating response: {str(e)}"}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
