/// Terms & Conditions body sections (en / ta).
class TermsContent {
  TermsContent._();

  static List<TermsSection> sections(String lang) {
    if (lang == 'ta') {
      return _ta;
    }
    return _en;
  }
}

class TermsSection {
  const TermsSection({required this.title, required this.body});
  final String title;
  final String body;
}

const _en = <TermsSection>[
  TermsSection(
    title: '1. About ProConnect',
    body:
        'ProConnect ("we", "the platform") connects customers with verified '
        'local service professionals for home repair and maintenance. By '
        'installing or using the app, you agree to these Terms & Conditions.',
  ),
  TermsSection(
    title: '2. Eligibility',
    body:
        'You must be 18 years or older and legally able to enter a contract. '
        'Professionals must complete identity verification (Aadhaar + selfie) '
        'and provide accurate skills, location, and pricing information.',
  ),
  TermsSection(
    title: '3. Bookings & payments',
    body:
        'Customers pay a visiting charge when booking a professional. Final '
        'service charges may differ after inspection. Payouts to professionals '
        'are processed per platform rules. We are not responsible for cash '
        'transactions outside the app.',
  ),
  TermsSection(
    title: '4. Professional conduct',
    body:
        'Professionals must arrive on time, behave respectfully, and complete '
        'agreed work safely. Customers must provide accurate addresses and '
        'access. Misuse, fraud, or harassment may lead to account suspension.',
  ),
  TermsSection(
    title: '5. Location & notifications',
    body:
        'The app uses your location to show nearby jobs or professionals and '
        'may send push notifications about bookings. You can manage notification '
        'permissions in device settings.',
  ),
  TermsSection(
    title: '6. Data & privacy',
    body:
        'We collect phone number, profile, booking, and device data to operate '
        'the service. KYC documents are stored securely for verification only. '
        'We do not sell your personal data to third parties.',
  ),
  TermsSection(
    title: '7. Limitation of liability',
    body:
        'ProConnect is a marketplace platform. Service quality is the '
        'responsibility of the professional. To the extent permitted by law, '
        'our liability is limited to the fees paid for the affected booking.',
  ),
  TermsSection(
    title: '8. Changes',
    body:
        'We may update these terms. Continued use after an update constitutes '
        'acceptance. Material changes may require renewed acceptance in the app.',
  ),
  TermsSection(
    title: '9. Contact',
    body:
        'Questions: support@proconnect.local or in-app Help. '
        'Governing law: India (Puducherry / Tamil Nadu jurisdiction where applicable).',
  ),
];

const _ta = <TermsSection>[
  TermsSection(
    title: '1. ProConnect பற்றி',
    body:
        'ProConnect ("நாங்கள்", "தளம்") வீட்டு பழுதுபார்ப்பு மற்றும் '
        'பராமரிப்புக்காக வாடிக்கையாளர்களை சரிபார்க்கப்பட்ட உள்ளூர் '
        'நிபுணர்களுடன் இணைக்கிறது. பயன்பாட்டை நிறுவுவதன் மூலம் அல்லது '
        'பயன்படுத்துவதன் மூலம் இந்த விதிமுறைகளை ஏற்கிறீர்கள்.',
  ),
  TermsSection(
    title: '2. தகுதி',
    body:
        'நீங்கள் 18 வயது மற்றும் அதற்கு மேற்பட்டவராக இருக்க வேண்டும். '
        'நிபுணர்கள் அடையாள சரிபார்ப்பு (ஆதார் + செல்ஃபி) முடித்து '
        'சரியான திறன், இருப்பிடம் மற்றும் விலை தகவலை வழங்க வேண்டும்.',
  ),
  TermsSection(
    title: '3. முன்பதிவு & கட்டணம்',
    body:
        'வாடிக்கையாளர் நிபுணரை முன்பதிவு செய்யும் போது வருகை கட்டணம் '
        'செலுத்துவார். பரிசோதனைக்குப் பிறகு இறுதி கட்டணம் மாறலாம். '
        'நிபுணர் வருமானம் தள விதிகளின்படி வழங்கப்படும்.',
  ),
  TermsSection(
    title: '4. நடத்தை',
    body:
        'நிபுணர்கள் நேரத்திற்கு வந்து மரியாதையுடன் பணியை முடிக்க வேண்டும். '
        'வாடிக்கையாளர் சரியான முகவரியை வழங்க வேண்டும். மோசடி அல்லது '
        'துஷ்பிரயோகம் கணக்கு நிறுத்தத்திற்கு வழிவகுக்கும்.',
  ),
  TermsSection(
    title: '5. இருப்பிடம் & அறிவிப்புகள்',
    body:
        'அருகிலுள்ள வேலைகள்/நிபுணர்களைக் காட்ட இருப்பிடம் பயன்படுத்தப்படும். '
        'முன்பதிவு அறிவிப்புகள் அனுப்பப்படலாம். அமைப்புகளில் அறிவிப்புகளை '
        'நிர்வகிக்கலாம்.',
  ),
  TermsSection(
    title: '6. தரவு & தனியுரிமை',
    body:
        'தொலைபேசி எண், சுயவிவரம், முன்பதிவு மற்றும் சாதன தரவு சேகரிக்கப்படும். '
        'KYC ஆவணங்கள் சரிபார்ப்புக்காக மட்டுமே பாதுகாப்பாக சேமிக்கப்படும்.',
  ),
  TermsSection(
    title: '7. பொறுப்பு வரம்பு',
    body:
        'ProConnect ஒரு இணைப்பு தளம். சேவை தரம் நிபுணரின் பொறுப்பு. '
        'சட்டப்படி அனுமதிக்கப்பட்ட வரம்பிற்குள் எங்கள் பொறுப்பு '
        'பாதிக்கப்பட்ட முன்பதிவுக்கான கட்டணத்திற்கு மட்டுப்படுத்தப்படும்.',
  ),
  TermsSection(
    title: '8. மாற்றங்கள்',
    body:
        'விதிமுறைகள் புதுப்பிக்கப்படலாம். தொடர்ந்த பயன்பாடு ஏற்பைக் '
        'குறிக்கிறது. முக்கிய மாற்றங்களுக்கு பயன்பாட்டில் மீண்டும் ஏற்பு '
        'தேவைப்படலாம்.',
  ),
  TermsSection(
    title: '9. தொடர்பு',
    body:
        'கேள்விகள்: support@proconnect.local அல்லது பயன்பாட்டில் Help. '
        'சட்டம்: இந்தியா.',
  ),
];
