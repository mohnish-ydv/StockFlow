import 'package:flutter/material.dart';

import '../core/theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Terms & Conditions',
      effectiveDate: 'Effective date: 18 August 2026',
      sections: [
        _LegalSection(
          heading: '1. About StockFlow',
          body:
              'StockFlow is a business-to-business marketplace for surplus, overstock and dead-stock inventory. The platform helps businesses discover stock, submit interest requests, use StockFlow-assisted deal coordination, unlock protected in-app communication when eligible, make offers and coordinate fulfilment. Buyer and seller contact details are not opened by default.',
        ),
        _LegalSection(
          heading: '2. Eligibility and business use',
          body:
              'You may use StockFlow only if you are legally capable of entering into a binding agreement and are using the service on behalf of yourself or a genuine business or commercial operation. You are responsible for ensuring that the information you provide is accurate and current.',
        ),
        _LegalSection(
          heading: '3. Accounts and verification',
          body:
              'You must provide a valid mobile number to access account features. You are responsible for activity under your account and for keeping your verification codes and device access secure. We may suspend or restrict access if we detect fraudulent, abusive or misleading behaviour.',
        ),
        _LegalSection(
          heading: '4. Listings and seller responsibilities',
          body:
              'Sellers must describe inventory truthfully, including condition, quantity, pricing, fulfilment options and any known defects or restrictions. Counterfeit, prohibited, stolen or unsafe goods are not allowed. Sellers are responsible for complying with applicable tax, safety, IP and commercial laws.',
        ),
        _LegalSection(
          heading: '5. Offers, negotiations and orders',
          body:
              'A buyer can submit an interest request without opening direct contact with the seller. StockFlow may coordinate the parties through marketplace operations. Protected buyer-seller chat and negotiation features may require a one-time promise fee for that deal. A confirmed order or accepted offer creates a commercial commitment between the parties, subject to the displayed order terms.',
        ),
        _LegalSection(
          heading: '6. Payments, pickup and shipping',
          body:
              'Payment methods, shipping arrangements, pickup timing, dispatch evidence and delivery communication may vary by listing and seller. Where a promise fee is offered to unlock protected chat, the fee is shown before confirmation and is non-refundable after the chat entitlement is granted, except where required by applicable law or where StockFlow fails to provide the paid unlock. Buyers remain responsible for reviewing order details and sellers for truthful fulfilment updates.',
        ),
        _LegalSection(
          heading: '7. Acceptable use',
          body:
              'You may not use StockFlow to deceive users, harvest data, spam, interfere with the service, bypass moderation, impersonate others, upload malicious material or trade in prohibited goods. Abuse of communication tools, fake offers, manipulative pricing or repeated non-fulfilment may result in account restriction or removal.',
        ),
        _LegalSection(
          heading: '8. Platform role and limitation',
          body:
              'StockFlow provides marketplace tools but is not the seller, buyer, courier, warehouse or insurer of listed goods. Except where required by law, we do not guarantee uninterrupted service, the quality of goods, or the conduct of individual users. StockFlow may assist with marketplace communication and dispute handling, but does not guarantee a commercial outcome between buyer and seller.',
        ),
        _LegalSection(
          heading: '9. Termination and policy updates',
          body:
              'We may update these terms from time to time to reflect product, operational or legal changes. Continued use of the service after an update means you accept the revised terms. We may suspend or terminate access where necessary to protect users, the platform or applicable legal obligations.',
        ),
        _LegalSection(
          heading: '10. Contact',
          body:
              'For account, safety or policy questions, contact the StockFlow support or admin team through the official channels provided inside the app or the admin site.',
        ),
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalScaffold(
      title: 'Privacy Policy',
      effectiveDate: 'Effective date: 18 August 2026',
      sections: [
        _LegalSection(
          heading: '1. Information we collect',
          body:
              'We collect information that you provide directly, such as your mobile number, full name, city, state, preferred language, shipping addresses, protected chat content, deal requests and listing details. If a seller explicitly chooses Use current location while posting, we also collect the device coordinates and accuracy for that stock location. We may collect technical information required to operate and secure the service, such as session identifiers, rate-limit identifiers and basic device or network metadata.',
        ),
        _LegalSection(
          heading: '2. Why we use your information',
          body:
              'We use your information to create and secure your account, verify logins, route interest requests, support StockFlow-assisted deal coordination, enable entitled in-app communication, support listings and orders, perform private location analytics, moderate marketplace activity, enforce anti-circumvention rules, investigate abuse and improve reliability and safety.',
        ),
        _LegalSection(
          heading: '3. Phone number privacy',
          body:
              'StockFlow keeps buyer and seller phone numbers private by default. Interest requests do not expose the buyer\'s contact details to the seller. Even after protected chat is unlocked, the service may block phone numbers, email addresses, social handles and external links to reduce off-platform circumvention. We use your number for sign-in, verification and account-related communication.',
        ),
        _LegalSection(
          heading: '4. Sharing of information',
          body:
              'We may share information when needed to operate the service—for example, with infrastructure or messaging providers—or when required by law, safety requests or fraud prevention. When a transaction or protected deal progresses, only operational details necessary for the authorised workflow may be visible to the relevant parties. Exact stock GPS coordinates are reserved for authorised StockFlow operations/admin analytics and are not exposed in the public buyer feed.',
        ),
        _LegalSection(
          heading: '5. Data retention',
          body:
              'We retain information for as long as necessary to operate the service, maintain marketplace records, enforce policies, resolve disputes and comply with legal obligations. Certain data may remain in backups or logs for a limited period even after it is removed from active systems.',
        ),
        _LegalSection(
          heading: '6. Security',
          body:
              'We take reasonable steps to protect account and marketplace data, including the use of controlled authentication flows and environment-based backend access. No method of storage or transmission is perfectly secure, so we cannot guarantee absolute security.',
        ),
        _LegalSection(
          heading: '7. Your choices',
          body:
              'You may review and update parts of your profile information in the app, and you may stop using the service at any time. If you need help with account access, data questions or policy requests, contact the official StockFlow support or admin channel.',
        ),
        _LegalSection(
          heading: '8. Policy changes',
          body:
              'We may update this privacy policy when the product, operations or legal requirements change. When material updates are made, the updated policy will be made available in the app with a revised effective date.',
        ),
      ],
    );
  }
}

class _LegalScaffold extends StatelessWidget {
  final String title;
  final String effectiveDate;
  final List<_LegalSection> sections;

  const _LegalScaffold({required this.title, required this.effectiveDate, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(effectiveDate, style: const TextStyle(color: StockFlowTheme.muted, fontSize: 13)),
                  const SizedBox(height: 16),
                  const Text(
                    'Please read this document carefully before creating or using a StockFlow account.',
                    style: TextStyle(color: StockFlowTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  for (final section in sections) ...[
                    Text(section.heading, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(section.body, style: const TextStyle(fontSize: 14.5, height: 1.6, color: StockFlowTheme.textSecondary)),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;
  const _LegalSection({required this.heading, required this.body});
}
