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

  'legal.terms.title': {
    'en': 'Terms & Conditions',
    'ta': 'விதிமுறைகள் & நிபந்தனைகள்',
  },
  'legal.terms.welcome': {
    'en': 'Welcome to ProConnect',
    'ta': 'ProConnect-க்கு வரவேற்கிறோம்',
  },
  'legal.terms.subtitle': {
    'en': 'Please read and accept our Terms & Conditions to continue.',
    'ta': 'தொடர, எங்கள் விதிமுறைகளைப் படித்து ஏற்கவும்.',
  },
  'legal.terms.updated': {
    'en': 'Last updated: July 2026',
    'ta': 'கடைசி புதுப்பிப்பு: ஜூலை 2026',
  },
  'legal.terms.checkbox': {
    'en':
        'I have read and agree to the Terms & Conditions and Privacy Policy.',
    'ta':
        'விதிமுறைகள் & நிபந்தனைகள் மற்றும் தனியுரிமைக் கொள்கையைப் படித்து ஏற்கிறேன்.',
  },
  'legal.terms.accept': {
    'en': 'Accept & Continue',
    'ta': 'ஏற்று தொடரவும்',
  },

  // Language select
  'lang.title': {
    'en': 'Choose your language',
    'ta': 'உங்கள் மொழியை தேர்வு செய்க',
  },
  'lang.subtitle': {
    'en': 'Pick Tamil or English',
    'ta': 'மொழியைத் தேர்ந்தெடுக்கவும்',
  },

  // Auth landing (sign-in home)
  'auth.landing.tagline': {
    'en':
        'Trusted local repair services — for professionals and customers.',
    'ta':
        'நம்பகமான உள்ளூர் பழுது சேவைகள் — நிபுணர்களுக்கும் வாடிக்கையாளர்களுக்கும்.',
  },
  'auth.landing.continue_title': {
    'en': 'How do you want to continue?',
    'ta': 'எப்படி தொடர விரும்புகிறீர்கள்?',
  },
  'auth.landing.continue_subtitle': {
    'en': 'Choose your role to sign in securely with OTP.',
    'ta': 'OTP மூலம் பாதுகாப்பாக உள்நுழைய உங்கள் பாத்திரத்தைத் தேர்ந்தெடுக்கவும்.',
  },
  'auth.landing.pro_title': {
    'en': 'Sign in · Professional',
    'ta': 'உள்நுழை · நிபுணர்',
  },
  'auth.landing.pro_subtitle': {
    'en': 'Accept jobs near you, track earnings, and grow your work.',
    'ta': 'அருகிலுள்ள வேலைகளை ஏற்கவும், வருமானத்தைக் கண்காணிக்கவும், வளரவும்.',
  },
  'auth.landing.customer_title': {
    'en': 'Need a Service · Customer',
    'ta': 'சேவை தேவை · வாடிக்கையாளர்',
  },
  'auth.landing.customer_subtitle': {
    'en': 'Book verified local technicians for AC, plumbing, and more.',
    'ta': 'ஏசி, குழாய் பணி மற்றும் பலவற்றிற்கு சரிபார்க்கப்பட்ட உள்ளூர் தொழில்நுட்பர்களை முன்பதிவு செய்யுங்கள்.',
  },
  'auth.landing.terms': {'en': 'Terms', 'ta': 'விதிமுறைகள்'},

  // Phone auth
  'auth.phone.title': {
    'en': 'Enter your mobile number',
    'ta': 'உங்கள் மொபைல் எண்ணை உள்ளிடவும்',
  },
  'auth.phone.helper': {
    'en': 'We will send a 6-digit OTP via SMS.',
    'ta': 'நாங்கள் SMS மூலம் 6-இலக்க OTP அனுப்புவோம்.',
  },
  'auth.signin.title': {'en': 'Sign in', 'ta': 'உள்நுழை'},
  'auth.signin.helper': {
    'en':
        'Enter the mobile number you used while enrolling. We will send a 6-digit OTP via SMS.',
    'ta':
        'பதிவு செய்யும் போது பயன்படுத்திய மொபைல் எண்ணை உள்ளிடவும். SMS மூலம் 6-இலக்க OTP அனுப்புவோம்.',
  },
  'auth.signin.send_otp': {'en': 'Send OTP', 'ta': 'OTP அனுப்பு'},
  'auth.signup.title': {
    'en': 'Create your account',
    'ta': 'உங்கள் கணக்கை உருவாக்குங்கள்',
  },
  'auth.signup.helper': {
    'en':
        'Enter the mobile number we should reach you on. We will send a 6-digit OTP via SMS.',
    'ta':
        'நாங்கள் தொடர்புகொள்ள வேண்டிய மொபைல் எண்ணை உள்ளிடவும். SMS மூலம் 6-இலக்க OTP அனுப்புவோம்.',
  },
  'auth.phone.trust': {
    'en': 'Verified pros only. We use OTP, never store your password.',
    'ta': 'சரிபார்க்கப்பட்ட நிபுணர்கள் மட்டும். OTP பயன்படுத்துகிறோம், கடவுச்சொல்லை சேமிக்க மாட்டோம்.',
  },
  'auth.signin.new_here': {
    'en': "New here? Tap back and choose 'Create account'.",
    'ta': 'புதியவரா? பின்சென்று ‘கணக்கு உருவாக்கு’ என்பதைத் தேர்ந்தெடுக்கவும்.',
  },
  'auth.signup.agree': {
    'en': 'By creating an account you agree to our Terms & Privacy Policy.',
    'ta': 'கணக்கு உருவாக்குவதன் மூலம் விதிமுறைகள் & தனியுரிமைக் கொள்கையை ஏற்கிறீர்கள்.',
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
    'en': 'Experience start year',
    'ta': 'அனுபவம் தொடங்கிய ஆண்டு',
  },
  'onboarding.experience.start_year_label': {
    'en': 'When did you start each service?',
    'ta': 'ஒவ்வொரு சேவையையும் எப்போது தொடங்கினீர்கள்?',
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
    'en': 'Set visiting charges',
    'ta': 'வருகை கட்டணங்களை அமைக்கவும்',
  },
  'onboarding.fee.helper': {
    'en':
        'Set a visit fee for each service (max ₹500). Customers only see the fee for the service they book.',
    'ta':
        'ஒவ்வொரு சேவைக்கும் வருகை கட்டணம் அமைக்கவும் (அதிகபட்சம் ₹500). வாடிக்கையாளர் பதிவு செய்யும் சேவையின் கட்டணத்தை மட்டும் பார்ப்பார்.',
  },
  'onboarding.fee.yourCharge': {
    'en': 'Your visiting charge',
    'ta': 'உங்கள் வருகை கட்டணம்',
  },
  'onboarding.fee.suggestedHint': {
    'en':
        'Suggested per service — adjust if needed. Platform fee (5%) is not shown to customers.',
    'ta':
        'சேவை வாரியாக பரிந்துரை — தேவைப்பட்டால் மாற்றவும். பிளாட்ஃபார்ம் கட்டணம் (5%) வாடிக்கையாளருக்கு காட்டப்படாது.',
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
  'kyc.pending.preview_hint': {
    'en':
        'You can continue into the app now to explore jobs, wallet, and profile while admin review finishes.',
    'ta':
        'நிர்வாக மதிப்பாய்வு முடியும் வரை வேலைகள், வாலட் மற்றும் சுயவிவரத்தை பார்க்க ஆப்ஸில் தொடரலாம்.',
  },
  'kyc.pending.continue': {
    'en': 'Continue to app',
    'ta': 'ஆப்பிற்கு தொடரவும்',
  },
  'kyc.pending.banner': {
    'en': 'KYC under review — exploring in preview mode',
    'ta': 'KYC மதிப்பாய்வில் — முன்னோட்ட பயன்முறை',
  },

  // Home shell
  'home.tab.jobs': {'en': 'Jobs', 'ta': 'வேலைகள்'},
  'home.tab.wallet': {'en': 'Wallet', 'ta': 'வாலட்'},
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
  'offer.finish_before_accept': {
    'en':
        'Finish your current job before accepting a new one.',
    'ta':
        'புதிய வேலையை ஏற்பதற்கு முன் தற்போதைய வேலையை முடிக்கவும்.',
  },
  'job.finish_current_first': {
    'en':
        'Finish or close your current job before starting the next one.',
    'ta':
        'அடுத்த வேலையைத் தொடங்குவதற்கு முன் தற்போதைய வேலையை முடிக்கவும் அல்லது மூடவும்.',
  },
  'offer.timer': {
    'en': 'Respond before work start · {time}',
    'ta': 'வேலை தொடங்கும் முன் பதிலளிக்கவும் · {time}',
  },
  'offer.timer_left': {
    'en': '{time} left to accept or reject',
    'ta': 'ஏற்க அல்லது நிராகரிக்க {time} உள்ளது',
  },
  'offer.expired': {
    'en':
        'This request expired. The customer was notified to book another pro.',
    'ta':
        'இந்த கோரிக்கை காலாவதியானது. வாடிக்கையாளருக்கு வேறு நிபுணரை முன்பதிவு செய்ய அறிவிக்கப்பட்டது.',
  },
  'offer.expired_short': {
    'en': 'Expired',
    'ta': 'காலாவதி',
  },
  'job.cancel': {'en': 'Reject job', 'ta': 'வேலையை நிராகரி'},
  'job.cancel_hint': {
    'en': 'You can reject while on the way. After you mark arrived, finish the job.',
    'ta': 'வரும் வழியில் இருக்கும் வரை நிராகரிக்கலாம். வந்துவிட்டேன் எனக் குறித்த பிறகு வேலையை முடிக்க வேண்டும்.',
  },
  'job.reject_reason_title': {
    'en': 'Why are you rejecting?',
    'ta': 'ஏன் நிராகரிக்கிறீர்கள்?',
  },
  'job.reject_reason_required': {
    'en': 'Please choose a reason to reject this job.',
    'ta': 'இந்த வேலையை நிராகரிக்க ஒரு காரணத்தைத் தேர்ந்தெடுக்கவும்.',
  },
  'job.reject_penalty_warning': {
    'en': 'You are on the way, so a penalty of {amount} will be deducted from your wallet.',
    'ta': 'நீங்கள் வரும் வழியில் உள்ளதால், {amount} அபராதம் உங்கள் வாலெட்டில் இருந்து கழிக்கப்படும்.',
  },
  'job.reject_reason.customer_unreachable': {
    'en': 'Customer not reachable',
    'ta': 'வாடிக்கையாளரைத் தொடர்பு கொள்ள முடியவில்லை',
  },
  'job.reject_reason.wrong_address': {
    'en': 'Wrong or unclear address',
    'ta': 'தவறான அல்லது தெளிவற்ற முகவரி',
  },
  'job.reject_reason.too_far': {
    'en': 'Location too far',
    'ta': 'இடம் மிகவும் தொலைவில் உள்ளது',
  },
  'job.reject_reason.vehicle_issue': {
    'en': 'Vehicle / breakdown issue',
    'ta': 'வாகனம் / பழுது சிக்கல்',
  },
  'job.reject_reason.emergency': {
    'en': 'Personal emergency',
    'ta': 'தனிப்பட்ட அவசரம்',
  },
  'job.reject_reason.other': {
    'en': 'Other reason',
    'ta': 'வேறு காரணம்',
  },
  'job.reject_reason_notes': {
    'en': 'Add a note (optional)',
    'ta': 'குறிப்பு சேர்க்கவும் (விருப்பம்)',
  },

  'job.on_the_way': {'en': 'On the way', 'ta': 'வரும் வழியில்'},
  'job.arrived': {'en': "I've arrived", 'ta': 'நான் வந்துவிட்டேன்'},
  'job.start': {'en': 'Start work', 'ta': 'வேலையை தொடங்கு'},
  'job.arrive_first': {
    'en': 'Mark arrived when you reach the customer location, then start work.',
    'ta': 'வாடிக்கையாளர் இடத்தை அடைந்த பிறகு வந்துவிட்டேன் எனக் குறித்து, பின்னர் வேலையை தொடங்குங்கள்.',
  },
  'job.too_far': {
    'en': 'You seem far from the customer. Reach the location, then mark arrived.',
    'ta': 'நீங்கள் வாடிக்கையாளரிடமிருந்து தொலைவில் உள்ளீர்கள். இடத்தை அடைந்த பிறகு குறிக்கவும்.',
  },
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
    'ta': 'வாடிக்கையாளர் பயன்முறைக்கு மாறு — பிளம்பர், ஏசி மெக்கானிக் போன்றவர்களைக் கண்டறியுங்கள்.',
  },

  // Customer home / book a service
  'customer.home.hi': {'en': 'Hi {name}!', 'ta': 'வணக்கம் {name}!'},
  'customer.home.need_fixed': {
    'en': 'What do you need fixed?',
    'ta': 'எதை சரிசெய்ய வேண்டும்?',
  },
  'customer.home.services': {'en': 'Services', 'ta': 'சேவைகள்'},
  'customer.home.online_pros': {
    'en': 'Online Professionals',
    'ta': 'ஆன்லைன் தொழில்நுட்பர்கள்',
  },
  'customer.home.current_work': {
    'en': 'Your current work',
    'ta': 'உங்கள் தற்போதைய வேலை',
  },
  'customer.home.location': {'en': 'Your location', 'ta': 'உங்கள் இடம்'},
  'customer.home.using_gps': {
    'en': 'Using your current location',
    'ta': 'தற்போதைய இடம் பயன்படுத்தப்படுகிறது',
  },
  'customer.home.detecting': {
    'en': 'Detecting your location...',
    'ta': 'இடம் கண்டறியப்படுகிறது...',
  },
  'customer.setup.title': {
    'en': 'Your details',
    'ta': 'உங்கள் விவரங்கள்',
  },
  'customer.setup.subtitle': {
    'en':
        'Tell us your name and location so we can match you with nearby pros.',
    'ta':
        'அருகிலுள்ள நிபுணர்களை இணைக்க உங்கள் பெயர் மற்றும் இடத்தைச் சொல்லுங்கள்.',
  },
  'customer.setup.name': {'en': 'Full name', 'ta': 'முழு பெயர்'},
  'customer.setup.name_hint': {
    'en': 'e.g. Priya Kumar',
    'ta': 'எ.கா. பிரியா குமார்',
  },
  'customer.setup.city': {'en': 'Your city', 'ta': 'உங்கள் நகரம்'},
  'customer.setup.detecting': {
    'en': 'Detecting your current location…',
    'ta': 'உங்கள் தற்போதைய இடத்தைக் கண்டறிகிறோம்…',
  },
  'customer.setup.using_location': {
    'en': 'Using your current location · {city}',
    'ta': 'உங்கள் தற்போதைய இடம் · {city}',
  },
  'customer.setup.gps_failed': {
    'en': 'Could not detect GPS. Select your city below.',
    'ta': 'GPS கண்டறிய முடியவில்லை. கீழே நகரத்தைத் தேர்ந்தெடுக்கவும்.',
  },
  'customer.setup.city_selected': {
    'en': 'City selected: {city}',
    'ta': 'தேர்ந்தெடுத்த நகரம்: {city}',
  },
  'customer.setup.use_current': {
    'en': 'Use current location',
    'ta': 'தற்போதைய இடத்தைப் பயன்படுத்து',
  },
  'customer.setup.phone': {
    'en': 'Phone: {phone}',
    'ta': 'தொலைபேசி: {phone}',
  },
  'customer.tab.home': {'en': 'Home', 'ta': 'முகப்பு'},
  'customer.tab.bookings': {'en': 'Bookings', 'ta': 'முன்பதிவுகள்'},
  'customer.tab.profile': {'en': 'Profile', 'ta': 'சுயவிவரம்'},
  'customer.profile.title': {'en': 'Profile', 'ta': 'சுயவிவரம்'},
  'customer.profile.location': {'en': 'Location', 'ta': 'இடம்'},
  'customer.profile.language': {'en': 'Language', 'ta': 'மொழி'},
  'customer.profile.switch_pro': {
    'en': 'Switch to Professional',
    'ta': 'தொழில்முறைக்கு மாறு',
  },
  'customer.profile.switch_pro_sub': {
    'en': 'Receive jobs for your enrolled services (AC, Plumber, …)',
    'ta': 'பதிவு செய்த சேவைகளுக்கான வேலைகளைப் பெறுங்கள் (ஏசி, பிளம்பர், …)',
  },
  'customer.profile.signout': {'en': 'Sign Out', 'ta': 'வெளியேறு'},

  'help.title': {'en': 'Help & Support', 'ta': 'உதவி & ஆதரவு'},
  'help.call': {'en': 'Call support', 'ta': 'ஆதரவை அழைக்க'},
  'help.whatsapp': {'en': 'WhatsApp us', 'ta': 'WhatsApp மூலம் தொடர்பு'},
  'help.faq': {'en': 'FAQ', 'ta': 'அடிக்கடி கேட்கப்படும் கேள்விகள்'},
  'help.experience_edit.title': {
    'en': 'Update experience years',
    'ta': 'அனுபவ ஆண்டுகளை புதுப்பிக்க',
  },
  'help.experience_edit.locked_body': {
    'en':
        'After enrollment, experience start year is locked. Raise a request for admin approval to edit it.',
    'ta':
        'பதிவுக்குப் பிறகு அனுபவ தொடக்க ஆண்டு பூட்டப்பட்டிருக்கும். திருத்த நிர்வாக ஒப்புதலுக்கு கோரிக்கை அனுப்பவும்.',
  },
  'help.experience_edit.unlocked_body': {
    'en':
        'Admin unlocked experience editing. Open Profile → My services, update the year, and save.',
    'ta':
        'நிர்வாகம் அனுபவ திருத்தத்தை அனுமதித்துள்ளது. சுயவிவரம் → என் சேவைகள் என்பதில் ஆண்டை மாற்றி சேமிக்கவும்.',
  },
  'help.experience_edit.pending': {
    'en': 'Request pending — waiting for admin approval.',
    'ta': 'கோரிக்கை நிலுவையில் — நிர்வாக ஒப்புதலுக்காக காத்திருக்கிறது.',
  },
  'help.experience_edit.request': {
    'en': 'Raise request to admin',
    'ta': 'நிர்வாகத்திற்கு கோரிக்கை அனுப்பு',
  },
  'help.experience_edit.submit': {'en': 'Submit request', 'ta': 'கோரிக்கை அனுப்பு'},
  'help.experience_edit.reason': {
    'en': 'Reason (optional)',
    'ta': 'காரணம் (விருப்பம்)',
  },
  'help.experience_edit.dialog_body': {
    'en':
        'Admin will review your request. After approval you can edit experience years once from Profile.',
    'ta':
        'நிர்வாகம் உங்கள் கோரிக்கையை பரிசீலிக்கும். ஒப்புதலுக்குப் பிறகு சுயவிவரத்தில் அனுபவ ஆண்டை ஒருமுறை திருத்தலாம்.',
  },
  'help.experience_edit.sent': {
    'en': 'Request sent to admin',
    'ta': 'கோரிக்கை நிர்வாகத்திற்கு அனுப்பப்பட்டது',
  },
  'help.experience_edit.go_profile': {
    'en': 'You can edit experience years now on Profile.',
    'ta': 'இப்போது சுயவிவரத்தில் அனுபவ ஆண்டுகளை திருத்தலாம்.',
  },
  'help.experience_edit.locked_hint': {
    'en':
        'Experience year is locked. Go to Help and raise a request for admin approval.',
    'ta':
        'அனுபவ ஆண்டு பூட்டப்பட்டுள்ளது. உதவி தாவலுக்குச் சென்று நிர்வாக ஒப்புதலுக்கு கோரிக்கை அனுப்பவும்.',
  },
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
