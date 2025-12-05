# GitHub Pages Setup Instructions

## Quick Setup

Your website is ready! Follow these steps to enable GitHub Pages:

### Step 1: Push to GitHub
```bash
git push origin main
```

### Step 2: Enable GitHub Pages
1. Go to your repository on GitHub: `https://github.com/Rebaseable/rebaseable-contracts`
2. Click on **Settings** (top right)
3. Scroll down to **Pages** in the left sidebar
4. Under **Source**, select:
   - **Branch**: `main`
   - **Folder**: `/docs`
5. Click **Save**

### Step 3: Access Your Site
Your site will be available at:
```
https://Rebaseable.github.io/rebaseable-contracts/
```

Note: It may take a few minutes for GitHub to build and deploy your site.

## Alternative: Using Root Directory

If you prefer to host from the root directory instead of `/docs`:

1. Move `docs/index.html` to `index.html` in the root
2. Update GitHub Pages settings to use `/ (root)` instead of `/docs`

## Troubleshooting

- **Site not loading?** Wait 5-10 minutes after enabling Pages
- **404 Error?** Make sure the branch is `main` and folder is `/docs`
- **Styling issues?** Check that `.nojekyll` file exists in the docs folder

## Custom Domain (Optional)

To use a custom domain:
1. Add a `CNAME` file in the `docs/` folder with your domain
2. Update DNS records as per GitHub's instructions

