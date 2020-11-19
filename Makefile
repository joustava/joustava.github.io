drafts:
	JEKYLL_ENV=production \
	bundle exec jekyll serve --drafts

qa:
	JEKYLL_ENV=production \
	bundle exec jekyll serve

deploy:
	JEKYLL_ENV=production \
	bundle exec jekyll build
	# git push origin main

.PHONY: develop drafts deploy