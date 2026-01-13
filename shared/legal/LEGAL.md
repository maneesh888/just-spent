# Just Spent - Legal Documents

This folder contains the legal documents required for App Store and Play Store compliance.

## 📄 Documents

### 1. Privacy Policy (`privacy-policy.html`)
- Comprehensive privacy policy covering data collection, usage, and user rights
- GDPR and CCPA compliant
- Covers voice data processing, encryption, and data retention
- Mobile-responsive HTML with clean styling

### 2. Terms and Conditions (`terms-and-conditions.html`)
- Complete terms of service for using Just Spent
- Includes disclaimers, limitations of liability, and user responsibilities
- Open-source license acknowledgment
- Mobile-responsive HTML with clean styling

## 🌐 Hosting Options

### Option 1: GitHub Pages (Recommended for Open Source)

1. **Enable GitHub Pages**:
   - Go to your repository settings
   - Navigate to "Pages" section
   - Source: Deploy from branch `main`
   - Folder: Select `/shared/legal` or `/` (root)
   - Save

2. **Access URLs**:
   - Privacy Policy: `https://maneesh888.github.io/just-spent/shared/legal/privacy-policy.html`
   - Terms: `https://maneesh888.github.io/just-spent/shared/legal/terms-and-conditions.html`

3. **Custom Domain (Optional)**:
   - Purchase domain (e.g., `justspent.app`)
   - Add CNAME record pointing to `<username>.github.io`
   - Configure in GitHub Pages settings
   - Access: `https://justspent.app/legal/privacy-policy.html`

### Option 2: Netlify / Vercel (Free Tier)

1. **Connect Repository**:
   - Sign up for free account
   - Connect GitHub repository
   - Deploy `/shared/legal` folder

2. **Access URLs**:
   - Automatic HTTPS
   - Custom subdomain: `just-spent.netlify.app/privacy-policy.html`

### Option 3: Firebase Hosting (Free Tier)

1. **Setup Firebase**:
   ```bash
   npm install -g firebase-tools
   firebase init hosting
   firebase deploy
   ```

2. **Configure**:
   - Public directory: `shared/legal`
   - Deploy to Firebase

### Option 4: Self-Hosted Server

Upload files to your own web server and serve via HTTPS.

## 📱 App Integration

### iOS (Swift)

Add to your app:

```swift
// SettingsView.swift or AboutView.swift

import SwiftUI

struct LegalLinksView: View {
    let privacyPolicyURL = URL(string: "https://maneesh888.github.io/just-spent/shared/legal/privacy-policy.html")!
    let termsURL = URL(string: "https://maneesh888.github.io/just-spent/shared/legal/terms-and-conditions.html")!

    var body: some View {
        VStack(spacing: 16) {
            Link("Privacy Policy", destination: privacyPolicyURL)
                .foregroundColor(.blue)

            Link("Terms and Conditions", destination: termsURL)
                .foregroundColor(.blue)
        }
    }
}
```

### Android (Kotlin/Compose)

Add to your app:

```kotlin
// SettingsScreen.kt or AboutScreen.kt

import androidx.compose.material3.TextButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext

@Composable
fun LegalLinks() {
    val context = LocalContext.current
    val privacyPolicyUrl = "https://maneesh888.github.io/just-spent/shared/legal/privacy-policy.html"
    val termsUrl = "https://maneesh888.github.io/just-spent/shared/legal/terms-and-conditions.html"

    Column {
        TextButton(onClick = {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(privacyPolicyUrl))
            context.startActivity(intent)
        }) {
            Text("Privacy Policy")
        }

        TextButton(onClick = {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(termsUrl))
            context.startActivity(intent)
        }) {
            Text("Terms and Conditions")
        }
    }
}
```

## 🍎 App Store Connect Configuration

When submitting to App Store:

1. **Privacy Policy URL**: Use the hosted URL
2. **Terms of Use URL**: Use the hosted URL
3. **Support URL**: Use GitHub repository or project website

Example:
- Privacy Policy: `https://maneesh888.github.io/just-spent/shared/legal/privacy-policy.html`
- Terms: `https://maneesh888.github.io/just-spent/shared/legal/terms-and-conditions.html`
- Support: `https://github.com/maneesh888/just-spent`

## 🤖 Google Play Console Configuration

When submitting to Play Store:

1. **Store Listing → Privacy Policy**: Enter hosted URL
2. **App Content → Privacy Policy**: Confirm URL
3. **App Content → Terms of Service**: (Optional) Enter URL if required

## 🔒 HTTPS Requirement

**Important**: Both App Store and Play Store require HTTPS URLs for legal documents. GitHub Pages provides HTTPS automatically.

## ✏️ Customization

### Update Placeholders

Before deploying, update:

1. **Email Addresses**:
   - Replace `privacy@justspent.app` with your actual email
   - Replace `legal@justspent.app` with your actual email
   - Replace `support@justspent.app` with your actual email

2. **Contact Information**:
   - Add your company/developer name if applicable
   - Update jurisdiction (currently placeholder: "[Your Jurisdiction]")

3. **Links**:
   - Update GitHub repository link if different
   - Update any placeholder URLs

### Branding

- Both files use Just Spent brand colors (#1976D2 primary blue)
- Modify CSS in `<style>` section to match your branding
- Logo can be added in header if desired

## 📋 Compliance Checklist

- [x] Privacy Policy covers data collection, usage, and sharing
- [x] Terms include disclaimers and limitations of liability
- [x] GDPR compliance (EU users' rights documented)
- [x] CCPA compliance (California users' rights documented)
- [x] COPPA compliance (age restrictions stated)
- [x] Voice data handling clearly explained
- [x] Open-source license acknowledgment
- [x] Contact information provided
- [x] Mobile-responsive design
- [x] HTTPS hosting plan documented

## 🔄 Maintenance

### When to Update

Update legal documents when:
- Adding new data collection or features
- Changing third-party service providers
- Expanding to new jurisdictions
- Receiving legal advice to modify terms
- Community reports issues or improvements

### Update Process

1. Edit HTML files in this directory
2. Update "Last Updated" date
3. Test in browser (mobile and desktop)
4. Commit changes to git
5. Deploy updates (automatic with GitHub Pages)
6. Notify users of material changes (in-app message)

## 🤝 Open Source Notes

These documents are specifically crafted for an open-source project:
- Acknowledge MIT License for source code
- Reference GitHub repository for transparency
- Allow community review and contributions
- Support self-hosting options

## 📧 Support

For questions about these legal documents:
- **GitHub Issues**: https://github.com/maneesh888/just-spent/issues
- **Email**: Update with your contact information

## ⚖️ Legal Disclaimer

These documents are provided as templates for an open-source project. While they cover common requirements for App Store and Play Store, you should:
- Consult with a lawyer if you have specific legal concerns
- Customize for your specific use case
- Ensure compliance with all applicable laws in your jurisdiction

---

**Last Updated**: January 12, 2025
