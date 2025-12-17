# audio2video
A vibe-coded batch program that lets you easily generate a video from an audio and image file, in a fast and efficient way using FFmpeg in Windows. Useful for people who wants to upload music to YouTube with a single image while retaining the highest audio quality using stream copy, so that it'll only be re-encoded once by YouTube's encoders.

## Usage

[FFmpeg](ffmpeg.org) is required to run this batch program.

audio2video was made to be as simple as possible, and you only need to specify two input files and an output file. Output format must be ``.mkv`` in most cases, being the container that has the most supported codecs.

``audio2video [image] [audio] [output].mkv [optional ffmpeg parameters]``

``audio2video Cheerleader.mp3 "SMILE Artwork.png" "Porter Robinson - Cheerleader.mkv"``

It actually also allows you to specify the image and audio file in reverse order, so you don't always have to remember it. It already has good defaults, but you can modify the FFmpeg options (to a certain extent) by adding additional parameters at the end of your command. If you need anything further than that, you'll have to modify the script itself. 

``audio2video "Lamplighter.jpg" "On Little Cat Feet (notcharldeon Remix).flac" OLCF_Remix.mkv -s 1080x1080 -veryslow -crf 10 -r 60 -t 0:05``

## How it works

Before I "created" this program, when I needed to upload an audio file to YouTube, I would have to specify the parameters every time in FFmpeg and also waste time rendering the entire video in my low-end laptop. It's a bigger problem when I have to render a 2-hour long compilation, so I had to find a better way. This program speeds up the process by (1) generating a temporary short video from the provided image using predefined parameters, and (2) looping the short video stream to generate a full video with the audio file losslessly muxed together without re-encoding to prevent quality loss. The base video generation parameters are:

``ffmpeg -loop 1 -r 25 -i "!image_file!" -c:v libx264 -preset veryfast -tune stillimage -pix_fmt yuv420p -crf 18 -t 10!extra_params! "!tempfile!" -y``

This generates a temporary video with the H.264/AVC codec using the ``libx264`` encoder, and I don't recommend using any another other encoding since it's already the fastest and most compatible codec anyway. ``-tune stillimage`` is set as default for obvious reasons. I also picked ``18`` as the base ``crf`` value, being the sweet spot between visual quality and file size. If you want higher quality, specify lower values like ``-crf 12`` or even go lossless with ``-crf 0`` if you have plenty of storage space and want to be overkill. If you want smaller file sizes while keeping the same crf, you can spend more time encoding the base video by using ``-preset veryslow`` or making it longer using ``-t [seconds]`` so that extra bitrate won't be wasted on unneccessary keyframes. The video is then looped using ``-stream_loop`` and merged together with the audio file using the second process:

``ffmpeg -stream_loop -1 -i "!tempfile!" -i "!audio_file!" -c:v copy -c:a copy -shortest "!output_file!"``

This prevents further quality loss by relying completely on stream copy.
