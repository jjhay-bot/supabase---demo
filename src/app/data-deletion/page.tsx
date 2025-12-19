import React from 'react';

export default function DataDeletion() {
  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <h1 className="text-3xl font-bold mb-6">Data Deletion Request</h1>
      
      <p className="mb-4">
        <strong>Effective Date:</strong> December 19, 2025
      </p>
      
      <p className="mb-4">
        We respect your privacy and give you control over your personal data. If you wish to delete your account and associated data, please follow the instructions below.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">How to Request Data Deletion</h2>
      <p className="mb-4">
        To request the deletion of your personal data and account:
      </p>
      <ol className="list-decimal list-inside mb-4">
        <li>Log in to your account on our application.</li>
        <li>Go to your profile settings.</li>
        <li>Click on "Delete Account" or "Request Data Deletion".</li>
        <li>Follow the prompts to confirm your request.</li>
      </ol>
      
      <p className="mb-4">
        Alternatively, you can contact us directly at [Your Contact Email] with your request. Please include your account email and any relevant details to verify your identity.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">What Happens After Deletion</h2>
      <p className="mb-4">
        Once your request is processed:
      </p>
      <ul className="list-disc list-inside mb-4">
        <li>Your account will be permanently deleted.</li>
        <li>All personal data associated with your account will be removed from our systems.</li>
        <li>We may retain certain data as required by law or for legitimate business purposes, anonymized where possible.</li>
      </ul>
      
      <h2 className="text-2xl font-semibold mb-4">Processing Time</h2>
      <p className="mb-4">
        We will process your data deletion request within 30 days of receiving it. You will receive a confirmation email once the deletion is complete.
      </p>
      
      <h2 className="text-2xl font-semibold mb-4">Contact Us</h2>
      <p className="mb-4">
        If you have any questions or need assistance with data deletion, please contact us at [Your Contact Email].
      </p>
    </div>
  );
}