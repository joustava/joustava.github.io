drafts:
	JEKYLL_ENV=production \
	bundle exec jekyll serve --drafts

qa:
	JEKYLL_ENV=production \
	bundle exec jekyll serve

.PHONY: develop