import React from 'react';

export default function PrivacyPolicy() {
  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <h1 className="text-3xl font-bold mb-6">Privacy Policy</h1>
      
      <p className="mb-4">
        <strong>Effective Date:</strong> December 19, 2025
      </p>
      
      <p className="mb-4">
        This Privacy Policy describes how we collect, use, and protect your information when you use our application and log in via Facebook.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">Information We Collect</h2>
      <p className="mb-4">
        When you log in using Facebook, we may collect the following information from your Facebook account:
      </p>
      <ul className="list-disc list-inside mb-4">
        <li>Name</li>
        <li>Email address</li>
        <li>Profile picture (if provided)</li>
        <li>Other public profile information you have made available on Facebook</li>
      </ul>
      
      <h2 className="text-2xl font-semibold mb-4">How We Use Your Information</h2>
      <p className="mb-4">
        We use the information collected to:
      </p>
      <ul className="list-disc list-inside mb-4">
        <li>Create and manage your account</li>
        <li>Provide personalized services</li>
        <li>Communicate with you about your account or our services</li>
        <li>Improve our application and user experience</li>
      </ul>
      
      <h2 className="text-2xl font-semibold mb-4">Information Sharing</h2>
      <p className="mb-4">
        We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy. We may share information with service providers who assist us in operating our application, subject to confidentiality agreements.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">Data Security</h2>
      <p className="mb-4">
        We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">Your Rights</h2>
      <p className="mb-4">
        You have the right to access, update, or delete your personal information. You can manage your Facebook data through your Facebook account settings.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">Changes to This Policy</h2>
      <p className="mb-4">
        We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">Contact Us</h2>
      <p className="mb-4">
        If you have any questions about this Privacy Policy, please contact us at [Your Contact Email].
      </p>
    </div>
  );
}