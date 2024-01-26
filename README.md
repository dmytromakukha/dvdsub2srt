# dvdsub2srt
The dvdsub2srt is a simple command line utility that parses video files with graphical subtitles and create text subtitles .srt-files.

## How it works
Some .mkv, .vob or .m2ts video files can contain subtitles from DVD or Blu-ray discs. These subtitles are graphic images that are displayed over the video. The [ffmpeg](https://www.ffmpeg.org/) library is used to decode these subtitles to images. The images are then transferred to the [Vision](https://developer.apple.com/documentation/vision/) framework for text recognition. The recognized text is saved to a text-based .srt file.

## Usage
```
dvdsub2srt [-s stream] [-l] <videofile>
```


 
