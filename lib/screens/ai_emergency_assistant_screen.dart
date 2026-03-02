import 'package:flutter/material.dart';

class AIEmergencyAssistantScreen extends StatelessWidget {
  const AIEmergencyAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC), // Slate 50
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI Assistant',
              style: TextStyle(
                color: Color(0xff1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is an AI generating emergency guidance, NOT a substitute for professional medical diagnosis. Call emergency services for severe cases.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[900],
                      height: 1.4,
                    ),
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAIMessage('Hello Jane. I am your Healthy Bhai AI assistant. What emergency guidance do you need today?'),
                _buildUserMessage('I have a high fever and I am a diabetic type 2. What should I do?'),
                _buildAIMessage(
                  'I understand you have a high fever and are a Type 2 Diabetic.\n\n'
                  'Here is immediate guidance:\n\n'
                  '1. Stay hydrated. Drink plenty of sugar-free fluids (water, clear broths).\n'
                  '2. Monitor your blood sugar closely. Fever can cause glucose levels to spike.\n'
                  '3. Take an over-the-counter fever reducer like Paracetamol if you are not allergic, but avoid NSAIDs (like Ibuprofen) unless directed by your doctor.\n'
                  '4. Rest.\n\n'
                  '**Seek immediate medical attention if:**\n'
                  '- Fever exceeds 103°F (39.4°C)\n'
                  '- You have difficulty breathing\n'
                  '- You experience confusion or severe weakness\n'
                  '- Blood sugar remains persistently high or low despite normal management.',
                ),
              ],
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
              bottom: MediaQuery.of(context).padding.bottom + 12, // notch safe
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Describe your symptoms...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic, color: Colors.blue),
                          onPressed: () {},
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffDC2626), // Red
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAIMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, right: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             margin: const EdgeInsets.only(top: 4, right: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy, color: Colors.blue[700], size: 16),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xff1E293B), // slate-800
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xff2563EB), // Blue 600
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
