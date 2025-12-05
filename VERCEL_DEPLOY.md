# Deploy to Vercel

## Option 1: Deploy via Vercel Web Interface (Recommended)

1. **Push your code to GitHub** (if not already done):
   ```bash
   git add .
   git commit -m "Add Vercel deployment files"
   git push origin main
   ```

2. **Go to Vercel**:
   - Visit: https://vercel.com
   - Sign up/Login with your GitHub account

3. **Import Project**:
   - Click "Add New..." → "Project"
   - Import your repository: `Rebaseable/rebaseable-contracts`
   - Vercel will auto-detect settings

4. **Configure Settings**:
   - **Framework Preset**: Other
   - **Root Directory**: `./` (leave as default)
   - **Output Directory**: `docs`
   - **Build Command**: Leave empty (or use: `echo 'No build needed'`)

5. **Deploy**:
   - Click "Deploy"
   - Your site will be live in seconds!

## Option 2: Deploy via Vercel CLI

1. **Login to Vercel**:
   ```bash
   npx vercel login
   ```

2. **Deploy**:
   ```bash
   npx vercel --prod
   ```

3. **Follow the prompts**:
   - Link to existing project or create new
   - Confirm settings
   - Deploy!

## Your Site URL

After deployment, Vercel will provide you with a URL like:
```
https://rebaseable-contracts.vercel.app
```

You can also add a custom domain in Vercel dashboard under Project Settings → Domains.

## Automatic Deployments

Once connected to GitHub, Vercel will automatically deploy:
- Every push to `main` branch → Production
- Pull requests → Preview deployments

## Troubleshooting

- **404 Error**: Make sure `outputDirectory` is set to `docs` in vercel.json
- **Styling not working**: Check that all paths are relative in index.html
- **Build fails**: Ensure vercel.json is in the root directory

