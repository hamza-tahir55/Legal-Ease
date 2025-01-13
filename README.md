# LegalEase: A Smart Legal Assistant

LegalEase is an AI-powered legal assistant designed to streamline legal case management by enabling users to upload case-related documents in PDF format, interact with a chatbot for legal queries, and receive dynamic questions to gather essential case details. This project leverages **Flutter** for the frontend and **Flask** for the backend.

---

## 💻 **Tech Stack**
- **Frontend:** Flutter (Dart)
- **Backend:** Flask (Python)
- **AI Models:** Google Generative AI (Gemini), Meta Llama 3-8b-8192
- **PDF Processing:** PyMuPDF
- **Dynamic Question Generation:** Groq API
- **Database:** Session-based storage (for temporary case data), Supabase Cloud (for community)

---

## 🛠 **Key Features**
### **Frontend (Flutter)**
- Chatbot UI for user interaction
- Lawyer listing with contact details
- PDF document upload and viewing
- Option to save responses and legal summaries as PDF
- Community

### **Backend (Flask)**
- AI-powered chatbot using Google Generative AI
- PDF content extraction and preprocessing
- Dynamic legal question generation based on user queries
- Language support for both **English** and **Urdu**
- Validation of case details (location, date, name)
- Tailored Legal Guidance 

---

## 🔍 **Core Functionalities**
1. **PDF Upload:** Users can upload case-related PDFs, which are processed to extract key content.
2. **Dynamic Questions:** The AI chatbot generates context-specific questions to collect case details.
3. **Chatbot Assistance:** Users can ask legal questions, and the chatbot provides accurate, AI-generated responses.
4. **Language Support:** The system responds in **English** or **Urdu** based on user preference.
5. **Case Summary Generation:** After gathering details, the system generates a legal case summary and advice.

---

## 🧩 **APIs & Libraries Used**
- **Google Generative AI (Gemini)** for Pdf-context chatbot responses and dynamic question generation
- **PyMuPDFLoader** for PDF content extraction
- **Flask** for backend routing and API handling
- **LangChain** for conversational AI integration
- **Meta Llama 3** for tailored legal guidance 

---

## 🔄 **Workflow**
1. User uploads a PDF document.
2. The backend processes the PDF and stores its content.
3. The user initiates a conversation with the chatbot.
4. The chatbot generates dynamic legal questions to gather more details.
5. The conversation data is compiled into a structured legal summary.

---

## 📋 **How to Run the Project**
### **Backend Setup (Flask)**
1. Clone the repository.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Set your API keys for Google Generative AI and Groq:
   ```bash
   export GOOGLE_API_KEY="your_api_key"
   export GROQ_API_KEY="your_groq_key"
   ```
4. Run the Flask server:
   ```bash
   python app.py
   ```

### **Frontend Setup (Flutter)**
1. Navigate to the frontend directory.
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the Flutter app:
   ```bash
   flutter run
   ```

---

## 📚 **File Structure**
```
LegalEase/
│
├── backend/
│   ├── app.py              # Main Flask app
│   ├── requirements.txt    # Dependencies
│   └── templates/
│       └── index.html      # Upload page template
│
└── frontend/
    ├── lib/
    │   └── main.dart       # Flutter app entry point
    └── pubspec.yaml        # Flutter dependencies
```

---

## 📦 **Future Enhancements**
- Implement user authentication for secure case management.
- Add more language support.
- Integrate with external legal databases for reference.
- Provide downloadable case summaries in multiple formats.

---

## ⚖️ **License**
This project is licensed under the **MIT License**. Feel free to use and modify it for your needs. 

