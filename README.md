# Flickr-Search

## Overview

This app allows users to query images using Flickr on iOS10+ devices. It supports endless scrolling and loading images for currently visible items.

## Workflows

The app downloads images for **On Screen** elements to optimise network calls. These images are cached in memory to avoid unnecessary duplicate hits. During scroll, all network calls are cancelled and resumed again once scrolling ends.

## Improvement areas

1. Pre-Download images for next batch of visible items. 
2. Persisting images in app's cache directory.
3. Display last 5-10 searched items.
4. Auto complete in search.
5. Siri based search trigger.
6. More unit testing.
 

