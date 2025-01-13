import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LawyerListScreen(),
    );
  }
}

class LawyerListScreen extends StatelessWidget {
  LawyerListScreen({super.key});

  // Sample list of lawyers with more details
  final List<Map<String, String>> lawyers = [
    {
      'name': 'Faisal Jameel Chouhan',
      'specialization': 'General Law',
      'location': 'Rawalpindi',
      'contact': '0321-5326931',
      'education': 'L.L.B (3 year)',
      'experience': '10+ years of experience in criminal defense.',
      'bio': 'I am a practicing lawyer based at Rawalpindi and Islamabad since last 15 years. I have vast experience in filing of cases, drafting and pleading in lower as well as high courts.',
      'imageUrl': 'assets/images/Faisal.png',  // Path to image in assets
    },
    {
      'name': 'Barrister Naveed Khan',
      'specialization': 'General Law, Consumer Law, Real State Law',
      'location': 'Islamabad',
      'contact': '0331-2376452',
      'education': 'Barrister,L.L.B,L.L.M (UK)',
      'experience': '8+ years of experience in civil disputes and contracts.',
      'bio': 'Mr. Naveed M. Khan is an English Barrister of the Honourable Society of Lincoln’s Inn with over 12 years of legal practice. He has an LLM (Masters in Law) degree from the UK. He is an expert in family, civil, criminal, and corporate law. He has a wide range of practice areas.',
      'imageUrl': 'assets/images/Naveed.png',// URL to online image
    },
    {
      'name': 'Barrister Wali Ahmed Soomro',
      'specialization': 'Family Law',
      'location': 'Karachi',
      'contact': '0300-9769462',
      'education': 'Barrister,L.L.B (3 year)',
      'experience': '5+ years of experience in family legal matters.',
      'bio': 'Expert in divorce, child custody, and family property disputes.',
      'imageUrl': 'assets/images/soomro.png',// URL to online image
    },
    {
      'name': 'Zarveen Amjad',
      'specialization': 'Family Law',
      'location': 'Karachi',
      'contact': '0333-3876661',
      'education': 'L.L.B (3 year),L.L.M',
      'experience': '2+ years of experience in Criminal Law.',
      'bio': 'Hello if u have any legal problem or abmiguity contact me ..',
      'imageUrl': 'assets/images/zarveen.png',// URL to online image
    },
    // Add more lawyers here with updated details
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Lawyers'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, location, or specialization',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                // Implement search functionality here
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: lawyers.length,
                itemBuilder: (context, index) {
                  return LawyerCard(
                    name: lawyers[index]['name']!,
                    specialization: lawyers[index]['specialization']!,
                    location: lawyers[index]['location']!,
                    contact: lawyers[index]['contact']!,
                    education: lawyers[index]['education']!,
                    experience: lawyers[index]['experience']!,
                    bio: lawyers[index]['bio']!,
                    imageUrl: lawyers[index]['imageUrl']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LawyerCard extends StatelessWidget {
  final String name;
  final String specialization;
  final String location;
  final String contact;
  final String education;
  final String experience;
  final String bio;
  final String imageUrl;

  const LawyerCard({
    super.key,
    required this.name,
    required this.specialization,
    required this.location,
    required this.contact,
    required this.education,
    required this.experience,
    required this.bio,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 6,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LawyerProfileScreen(
                name: name,
                contact: contact,
                education: education,
                experience: experience,
                bio: bio,
                imageUrl: imageUrl,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: imageUrl.startsWith('http')
                    ? NetworkImage(imageUrl) // Load image from network
                    : AssetImage(imageUrl) as ImageProvider, // Load image from assets
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(specialization, style: const TextStyle(color: Colors.grey)),
                    Text(location, style: const TextStyle(color: Colors.blueAccent)),
                    const SizedBox(height: 5),
                    Text('Education: $education', style: const TextStyle(fontSize: 12)),
                    Text('Experience: $experience', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LawyerProfileScreen(
                              name: name,
                              contact: contact,
                              education: education,
                              experience: experience,
                              bio: bio,
                              imageUrl: imageUrl,
                            ),
                          ),
                        );
                      },
                      child: const Text('Contact Lawyer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _contactLawyer(String contact) {
    // You can add functionality to call or email the lawyer using contact details
    print("Contacting lawyer at: $contact");
  }
}

class LawyerProfileScreen extends StatelessWidget {
  final String name;
  final String contact;
  final String education;
  final String experience;
  final String bio;
  final String imageUrl;

  const LawyerProfileScreen({
    super.key,
    required this.name,
    required this.contact,
    required this.education,
    required this.experience,
    required this.bio,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lawyer's image
              CircleAvatar(
                radius: 60,
                backgroundImage: imageUrl.startsWith('http')
                    ? NetworkImage(imageUrl)
                    : AssetImage(imageUrl) as ImageProvider,
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),

              // Contact
              Text(
                contact,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              // Information container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Education
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.school, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Education: $education',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Experience
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.work, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Experience: $experience',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Bio
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bio: $bio',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
