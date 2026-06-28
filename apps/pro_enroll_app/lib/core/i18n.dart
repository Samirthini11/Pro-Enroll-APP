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
  'common.ok': {'en': 'OK', 'ta': 'சரி'},
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
  'auth.otp.invalid_title': {
    'en': 'Invalid OTP',
    'ta': 'தவறான OTP',
  },
  'auth.otp.invalid': {
    'en': 'Incorrect OTP. Please check the code and try again.',
    'ta': 'தவறான OTP. குறியீட்டை சரிபார்த்து முயற்சிக்கவும்.',
  },
  'auth.otp.session_expired': {
    'en': 'OTP session expired. Go back and request a new code.',
    'ta': 'OTP காலாவதியானது. திரும்பிச் சென்று புதிய குறியீட்டை கோரவும்.',
  },
  'auth.signup.otp.title': {
    'en': 'Create account — Verify OTP',
    'ta': 'கணக்கு உருவாக்கம் — OTP சரிபார்ப்பு',
  },
  'auth.signup.otp.helper': {
    'en': 'Enter the 6-digit code we sent to {phone} to finish creating your account.',
    'ta': 'உங்கள் கணக்கை உருவாக்க {phone} -க்கு அனுப்பிய 6-இலக்க குறியீட்டை உள்ளிடவும்.',
  },
  'auth.signup.otp.verify': {
    'en': 'Verify & create account',
    'ta': 'சரிபார்த்து கணக்கை உருவாக்கு',
  },

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
        'We use your current location to pick the nearest city and show jobs within your radius.',
    'ta':
        'அருகிலுள்ள நகரத்தைத் தேர்ந்தெடுக்கவும், உங்கள் எல்லைக்குள் வேலைகளைக் காட்டவும் தற்போதைய இருப்பிடத்தைப் பயன்படுத்துகிறோம்.',
  },
  'onboarding.location.city': {'en': 'City', 'ta': 'நகரம்'},
  'onboarding.location.radius': {
    'en': 'Work radius (km)',
    'ta': 'வேலை எல்லை (கி.மீ)',
  },
  'onboarding.location.detecting': {
    'en': 'Detecting your location…',
    'ta': 'உங்கள் இருப்பிடம் கண்டறியப்படுகிறது…',
  },
  'onboarding.location.using_gps': {
    'en': 'Using your current location',
    'ta': 'தற்போதைய இருப்பிடம் பயன்படுத்தப்படுகிறது',
  },
  'onboarding.location.use_current': {
    'en': 'Use current location',
    'ta': 'தற்போதைய இருப்பிடத்தைப் பயன்படுத்து',
  },
  'onboarding.location.unavailable': {
    'en': 'Location unavailable — pick your city manually.',
    'ta': 'இருப்பிடம் கிடைக்கவில்லை — நகரத்தை கைமுறையாகத் தேர்ந்தெடுக்கவும்.',
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
  'earnings.subtitle': {
    'en': 'Your performance & payout overview',
    'ta': 'உங்கள் செயல்திறன் & பணம் வரவு சுருக்கம்',
  },
  'earnings.today': {'en': 'Today', 'ta': 'இன்று'},
  'earnings.week': {'en': 'This week', 'ta': 'இந்த வாரம்'},
  'earnings.month': {'en': 'This month', 'ta': 'இந்த மாதம்'},
  'earnings.payouts': {'en': 'Payouts', 'ta': 'பணம் வரவு'},
  'earnings.payoutsSubtitle': {
    'en': 'Track pending and settled amounts',
    'ta': 'நிலுவை மற்றும் செலுத்தப்பட்ட தொகைகளை கண்காணிக்கவும்',
  },
  'earnings.performance': {
    'en': 'Performance overview',
    'ta': 'செயல்திறன் சுருக்கம்',
  },
  'earnings.reviews': {'en': '{count} reviews', 'ta': '{count} மதிப்பீடுகள்'},
  'earnings.noReviews': {'en': 'No reviews yet', 'ta': 'இன்னும் மதிப்பீடு இல்லை'},
  'earnings.completed': {'en': 'completed', 'ta': 'முடிந்தது'},
  'earnings.strongProfile': {'en': 'Strong profile', 'ta': 'வலுவான சுயவிவரம்'},
  'earnings.keepImproving': {'en': 'Keep improving', 'ta': 'தொடர்ந்து முன்னேறுங்கள்'},
  'earnings.visitFee': {'en': 'Visit fee', 'ta': 'வருகை கட்டணம்'},
  'earnings.perVisit': {'en': 'per visit', 'ta': 'ஒரு வருகைக்கு'},
  'earnings.jobsTodayOne': {
    'en': '1 job completed today',
    'ta': 'இன்று 1 வேலை முடிந்தது',
  },
  'earnings.jobsTodayMany': {
    'en': '{count} jobs completed today',
    'ta': 'இன்று {count} வேலைகள் முடிந்தது',
  },
  'earnings.dailyAvg': {
    'en': '{amount} avg / day',
    'ta': 'சராசரி {amount} / நாள்',
  },
  'earnings.lifetimeJobs': {
    'en': '{count} lifetime jobs',
    'ta': 'மொத்தம் {count} வேலைகள்',
  },
  'earnings.noJobsYet': {'en': 'No jobs yet', 'ta': 'இன்னும் வேலை இல்லை'},
  'earnings.pending': {'en': 'Pending', 'ta': 'நிலுவை'},
  'earnings.paidMonth': {'en': 'Paid this month', 'ta': 'இந்த மாதம் செலுத்தப்பட்டது'},
  'earnings.paidProgress': {'en': 'Settled this month', 'ta': 'இந்த மாதம் தீர்வு'},
  'earnings.totalMonth': {'en': 'Earned this month', 'ta': 'இந்த மாதம் வருவாய்'},
  'earnings.payoutTo': {'en': 'Payout to', 'ta': 'பணம் அனுப்ப'},
  'earnings.payoutNotSet': {
    'en': 'Add UPI in Profile',
    'ta': 'சுயவிவரத்தில் UPI சேர்க்கவும்',
  },
  'earnings.insights': {'en': 'Insights', 'ta': 'பகுப்பாய்வு'},
  'earnings.insightGoOnline': {
    'en': 'Go online to receive more job offers and grow earnings.',
    'ta': 'ஆன்லைனில் இருந்து அதிக வேலை ஆஃபர்களைப் பெறுங்கள்.',
  },
  'earnings.insightGreatDay': {
    'en': 'Great progress today — keep your availability on for more jobs.',
    'ta': 'இன்று நல்ல முன்னேற்றம் — அதிக வேலைகளுக்கு ஆன்லைனில் இருங்கள்.',
  },
  'earnings.insightRating': {
    'en': 'Your {rating}★ rating helps you win more bookings.',
    'ta': 'உங்கள் {rating}★ மதிப்பீடு அதிக booking-களை வெல்ல உதவும்.',
  },
  'earnings.insightNoRating': {
    'en': 'Complete jobs and collect ratings to boost your Pro Score.',
    'ta': 'வேலைகளை முடித்து மதிப்பீடுகளைப் பெற Pro Score-ஐ உயர்த்துங்கள்.',
  },
  'earnings.insightVisitFee': {
    'en': 'Your visit fee is {fee} — adjust it in Profile if needed.',
    'ta': 'உங்கள் வருகை கட்டணம் {fee} — தேவைப்பட்டால் சுயவிவரத்தில் மாற்றவும்.',
  },

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
  'profile.bookService': {
    'en': 'Book a service',
    'ta': 'சேவை முன்பதிவு',
  },
  'profile.bookService.subtitle': {
    'en': 'Switch to customer mode — find a Plumber, AC tech, etc.',
    'ta': 'வாடிக்கையாளர் பயன்முறைக்கு மாறு — Plumber, AC tech போன்றவர்களைக் கண்டறியுங்கள்.',
  },

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
