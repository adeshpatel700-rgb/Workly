const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 1. Initialize Admin SDK
const serviceAccount = require(path.join(__dirname, 'scripts/service_account.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function deployRules() {
  console.log('📝 Reading firestore.rules...');
  const rulesPath = path.join(__dirname, 'firestore.rules');
  
  if (!fs.existsSync(rulesPath)) {
    console.error('❌ firestore.rules not found!');
    return;
  }

  const source = fs.readFileSync(rulesPath, 'utf8');

  try {
    console.log('🚀 Deploying Security Rules...');
    
    // Create new ruleset
    const ruleset = await admin.securityRules().createRuleset({
      source: {
        files: [{
          name: 'firestore.rules',
          content: source
        }]
      }
    });

    console.log(`✅ Ruleset created: ${ruleset.name}`);

    // Release (activate) the ruleset
    await admin.securityRules().releaseFirestoreRuleset(ruleset.name);
    console.log('✅ Firestore Security Rules deployed successfully!');
    
  } catch (error) {
    console.error('❌ Failed to deploy rules:', error);
  }
}

deployRules();
