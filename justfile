set dotenv-load := false

# Serve site locally with drafts
develop:
    JEKYLL_ENV=development bundle exec jekyll serve --drafts --livereload

# Serve site locally without drafts
qa:
    JEKYLL_ENV=production bundle exec jekyll serve --livereload

# Build site for production
deploy:
    JEKYLL_ENV=production bundle exec jekyll build
    git push origin main
