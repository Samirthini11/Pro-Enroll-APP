import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/locale_state.dart';

/// Tiny in-app translation helper.
///
/// We deliberately avoid the full ARB / `flutter gen-l10n` toolchain in
/// this MVP scaffold so the codebase stays easy to read. For production
/// migrate this map into ARB files.
const _strings = <String, Map<String, String>>{
  'app.name': {
    'en': 'Pro-Enroll',
    'ta': 'Pro-Enroll',
  },

  // Splash / common
  'common.next': {'en': 'Next', 'ta': 'அடுத்து'},
  'common.continue': {'en': 'Continue', 'ta': 'தொடரவும்'},
  'common.submit': {'en': 'Submit', 'ta': 'சமர்ப்பிக்கவும்'},
  'common.skip': {'en': 'Skip', 'ta': 'தவிர்'},
  'common.back': {'en': 'Back', 'ta': 'பின்செல்'},
  'common.save': {'en': 'Save', 'ta': 'சேமி'},
  'common.cancel': {'en': 'Cancel', 'ta': 'ரத்து'},
  'common.yes': {'en': 'Yes', 'ta': 'ஆம்'},
  'common.no': {'en': 'No', 'ta': 'இல்லை'},
  'common.online': {'en': 'Online', 'ta': 'ஆன்லைன்'},
  'common.offline': {'en': 'Offline', 'ta': 'ஆஃப்லைன்'},

  // Splash
  'splash.tagline': {
    'en': 'Local skills. Verified hands. Daily payouts.',
    'ta': 'உள்ளூர் திறமை. சரிபார்க்கப்பட்ட நிபுணர். தினசரி வருமானம்.',
  },

  // Language select
  'lang.title': {
    'en': 'Choose your language',
    'ta': 'உங்கள் மொழியை தேர்வு செய்க',
  },

  // Phone auth
  'auth.phone.title': {
    'en': 'Enter your mobile number',
    'ta': 'உங்கள் மொபைல் எண்ணை உள்ளிடவும்',
  },
  'auth.phone.helper': {
    'en': 'We will send a 6-digit OTP via SMS.',
    'ta': 'நாங்கள் SMS மூலம் 6-இலக்க OTP அனுப்புவோம்.',
  },
  'auth.otp.title': {'en': 'Verify OTP', 'ta': 'OTP சரிபார்க்கவும்'},
  'auth.otp.helper': {
    'en': 'Enter the 6-digit code sent to {phone}',
    'ta': '{phone} -க்கு அனுப்பப்பட்ட 6-இலக்க குறியீட்டை உள்ளிடவும்',
  },
  'auth.otp.resend': {'en': 'Resend OTP', 'ta': 'மீண்டும் OTP அனுப்பு'},

  // Onboarding
  'onboarding.welcome.title': {
    'en': 'Welcome to Pro-Enroll',
    'ta': 'Pro-Enroll க்கு வரவேற்கிறோம்',
  },
  'onboarding.welcome.subtitle': {
    'en':
        'Get verified, get jobs near you, get paid daily to your UPI.\n\nIt takes about 5 minutes to enroll.',
    'ta':
        'சரிபார்க்கப்பட்டு, உங்கள் அருகில் உள்ள வேலைகளைப் பெறுங்கள், தினசரி உங்கள் UPI க்கு வருமானம் பெறுங்கள்.\n\nபதிவுக்கு சுமார் 5 நிமிடம் ஆகும்.',
  },
  'onboarding.welcome.cta': {
    'en': 'Start enrollment',
    'ta': 'பதிவை தொடங்கு',
  },

  'onboarding.category.title': {
    'en': 'What work do you do?',
    'ta': 'நீங்கள் என்ன வேலை செய்கிறீர்கள்?',
  },
  'onboarding.category.helper': {
    'en': 'Pick up to 3 categories you can work in.',
    'ta':
        'நீங்கள் வேலை செய்யக்கூடிய 3 வகைகள் வரை தேர்ந்தெடுக்கவும்.',
  },

  'onboarding.experience.title': {
    'en': 'Years of experience',
    'ta': 'எத்தனை ஆண்டு அனுபவம்?',
  },

  'onboarding.location.title': {
    'en': 'Where do you work?',
    'ta': 'நீங்கள் எங்கே வேலை செய்கிறீர்கள்?',
  },
  'onboarding.location.helper': {
    'en':
        'We will only show you jobs from customers inside your chosen radius.',
    'ta':
        'நீங்கள் தேர்ந்தெடுத்த தூரத்திற்குள் உள்ள வாடிக்கையாளர்களின் வேலைகளை மட்டுமே காண்பிப்போம்.',
  },
  'onboarding.location.city': {'en': 'City', 'ta': 'நகரம்'},
  'onboarding.location.radius': {
    'en': 'Work radius (km)',
    'ta': 'வேலை எல்லை (கி.மீ)',
  },

  'onboarding.fee.title': {
    'en': 'Set your visit fee',
    'ta': 'உங்கள் வருகை கட்டணத்தை அமைக்கவும்',
  },
  'onboarding.fee.helper': {
    'en':
        'This is the fixed fee a customer pays when you visit, before any repair work.',
    'ta':
        'உங்கள் வருகை நேரத்தில், எந்த பழுதுபார்ப்பும் தொடங்குவதற்கு முன், வாடிக்கையாளர் செலுத்தும் நிலையான கட்டணம் இது.',
  },

  // KYC
  'kyc.intro.title': {
    'en': 'Verify your identity',
    'ta': 'உங்கள் அடையாளத்தை சரிபார்க்கவும்',
  },
  'kyc.intro.body': {
    'en':
        'For customer trust, every professional must complete a quick KYC:\n\n  1. Aadhaar verification (OTP based)\n  2. A live selfie\n  3. Optional: shop / tools photo, skill certificate\n\nYour Aadhaar number is encrypted and only its last 4 digits are stored.',
    'ta':
        'வாடிக்கையாளர் நம்பிக்கைக்காக, ஒவ்வொரு நிபுணரும் ஒரு விரைவான KYC முடிக்க வேண்டும்:\n\n  1. ஆதார் சரிபார்ப்பு (OTP மூலம்)\n  2. லைவ் செல்ஃபி\n  3. விருப்பத்தேர்வு: கடை / கருவிகள் புகைப்படம், திறமை சான்றிதழ்\n\nஉங்கள் ஆதார் எண் என்க்ரிப்ட் செய்யப்பட்டு, கடைசி 4 இலக்கங்கள் மட்டுமே சேமிக்கப்படும்.',
  },
  'kyc.aadhaar.title': {
    'en': 'Aadhaar verification',
    'ta': 'ஆதார் சரிபார்ப்பு',
  },
  'kyc.aadhaar.helper': {
    'en':
        'Enter your 12-digit Aadhaar number. We will send an OTP to your linked mobile.',
    'ta':
        'உங்கள் 12-இலக்க ஆதார் எண்ணை உள்ளிடவும். உங்கள் இணைக்கப்பட்ட மொபைலுக்கு ஒரு OTP அனுப்புவோம்.',
  },
  'kyc.selfie.title': {'en': 'Take a live selfie', 'ta': 'லைவ் செல்ஃபி எடுக்கவும்'},
  'kyc.selfie.body': {
    'en':
        'Hold your phone at eye level, look at the camera and blink. Make sure your face is clearly visible and well-lit.',
    'ta':
        'உங்கள் போனை கண்மட்டத்தில் பிடித்து, கேமராவை பார்த்து கண் சிமிட்டவும். உங்கள் முகம் தெளிவாக தெரிய வேண்டும்.',
  },
  'kyc.docs.title': {
    'en': 'Supporting documents',
    'ta': 'ஆதரவு ஆவணங்கள்',
  },
  'kyc.docs.body': {
    'en':
        'Optional but boosts your Pro Score. Upload any:\n\n  • Tools / shop photo\n  • Skill / training certificate\n  • PAN card',
    'ta':
        'விருப்பத்தேர்வு ஆனால் உங்கள் Pro Score-ஐ அதிகரிக்கும். பதிவேற்றவும்:\n\n  • கருவி / கடை புகைப்படம்\n  • திறமை / பயிற்சி சான்றிதழ்\n  • PAN கார்டு',
  },
  'kyc.pending.title': {
    'en': 'KYC under review',
    'ta': 'KYC மதிப்பாய்வில் உள்ளது',
  },
  'kyc.pending.body': {
    'en':
        'Thanks! Our team usually verifies new pros within 2–4 working hours.\n\nWe will notify you as soon as your account is live.',
    'ta':
        'நன்றி! எங்கள் குழு வழக்கமாக 2–4 வேலை மணி நேரத்திற்குள் புதிய நிபுணர்களை சரிபார்க்கும்.\n\nஉங்கள் கணக்கு செயல்படத் தொடங்கியதும் அறிவிப்போம்.',
  },

  // Home shell
  'home.tab.jobs': {'en': 'Jobs', 'ta': 'வேலைகள்'},
  'home.tab.earnings': {'en': 'Earnings', 'ta': 'வருமானம்'},
  'home.tab.profile': {'en': 'Profile', 'ta': 'சுயவிவரம்'},
  'home.tab.help': {'en': 'Help', 'ta': 'உதவி'},

  'jobs.title': {'en': 'Jobs near you', 'ta': 'உங்கள் அருகில் வேலைகள்'},
  'jobs.empty.title': {
    'en': 'No new jobs right now',
    'ta': 'இப்போது புதிய வேலைகள் இல்லை',
  },
  'jobs.empty.body': {
    'en':
        'Stay Online to receive job offers. We will notify you as soon as a customer in your area needs you.',
    'ta':
        'வேலை ஆஃபர்களைப் பெற ஆன்லைனில் இருங்கள். உங்கள் பகுதியில் வாடிக்கையாளருக்கு உங்கள் தேவை ஏற்படும் போது அறிவிப்போம்.',
  },
  'jobs.available_toggle': {
    'en': 'Available for jobs',
    'ta': 'வேலைகளுக்கு கிடைக்கிறேன்',
  },

  'offer.title': {'en': 'New job offer', 'ta': 'புதிய வேலை ஆஃபர்'},
  'offer.accept': {'en': 'Accept', 'ta': 'ஏற்க'},
  'offer.reject': {'en': 'Reject', 'ta': 'நிராகரிக்க'},
  'offer.timer': {
    'en': 'Auto-rejects in {sec}s',
    'ta': '{sec} வினாடிகளில் தானாக நிராகரிக்கப்படும்',
  },

  'job.on_the_way': {'en': 'On the way', 'ta': 'வரும் வழியில்'},
  'job.start': {'en': 'Start work', 'ta': 'வேலையை தொடங்கு'},
  'job.complete': {'en': 'Complete job', 'ta': 'வேலையை முடி'},
  'job.final_amount': {
    'en': 'Final amount (₹)',
    'ta': 'இறுதி தொகை (₹)',
  },

  'earnings.title': {'en': 'Earnings', 'ta': 'வருமானம்'},
  'earnings.today': {'en': 'Today', 'ta': 'இன்று'},
  'earnings.week': {'en': 'This week', 'ta': 'இந்த வாரம்'},
  'earnings.month': {'en': 'This month', 'ta': 'இந்த மாதம்'},
  'earnings.payouts': {'en': 'Payouts', 'ta': 'பணம் வரவு'},

  'profile.title': {'en': 'My profile', 'ta': 'என் சுயவிவரம்'},
  'profile.rating': {'en': 'Rating', 'ta': 'மதிப்பீடு'},
  'profile.jobs': {'en': 'Jobs done', 'ta': 'முடிந்த வேலைகள்'},
  'profile.proScore': {'en': 'Pro Score', 'ta': 'Pro மதிப்பு'},
  'profile.bank.title': {
    'en': 'Bank & UPI for payouts',
    'ta': 'பணப் பெறுதலுக்கான வங்கி & UPI',
  },
  'profile.bank.empty': {
    'en': 'Add your bank or UPI to receive daily payouts.',
    'ta': 'தினசரி பணம் பெற உங்கள் வங்கி அல்லது UPI ஐ சேர்க்கவும்.',
  },
  'profile.language': {'en': 'Language', 'ta': 'மொழி'},
  'profile.signout': {'en': 'Sign out', 'ta': 'வெளியேறு'},

  'help.title': {'en': 'Help & Support', 'ta': 'உதவி & ஆதரவு'},
  'help.call': {'en': 'Call support', 'ta': 'ஆதரவை அழைக்க'},
  'help.whatsapp': {'en': 'WhatsApp us', 'ta': 'WhatsApp மூலம் தொடர்பு'},
  'help.faq': {'en': 'FAQ', 'ta': 'அடிக்கடி கேட்கப்படும் கேள்விகள்'},
};

class L {
  const L(this.lang);
  final String lang;

  String t(String key, [Map<String, String>? params]) {
    final entry = _strings[key];
    if (entry == null) return key;
    var text = entry[lang] ?? entry['en'] ?? key;
    if (params != null) {
      for (final e in params.entries) {
        text = text.replaceAll('{${e.key}}', e.value);
      }
    }
    return text;
  }
}

final lProvider = Provider<L>((ref) {
  final locale = ref.watch(localeProvider);
  return L(locale.languageCode);
});

extension LContextX on BuildContext {
  // Convenience for non-Riverpod widgets (rare).
  String tr(WidgetRef ref, String key, [Map<String, String>? params]) =>
      ref.read(lProvider).t(key, params);
}
