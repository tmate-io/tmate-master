/*
 * If you are curious, here is how I generated the videos:
 *   ffmpeg -an -f x11grab -r 30 -s 460x285 -i :0.0+1920,0 -pix_fmt yuv444p -vcodec libx264 -x264opts crf=0 out.mp4
 *   mplayer -fps 3000 -vo png out.mp4
 *   montage *.png -tile x14 -geometry '460x285' out.png
 *   pngcrush out.png video.png
 *
 *   Safari and Firefox don't like very wide pngs, so we chunk the frames in
 *   rows. Sadly it makes the png bigger.
 */

$(function() {
  var video_linux = $('.video.linux');
  var video_macos = $('.video.macos');
  var current_frame = 0;
  var timer;

  var nextFrameFor = function(video, rows, total_frames, offset) {
    var frame = current_frame - offset;
    if (frame < 0)
      return;

    var frames_per_row = Math.ceil(total_frames / rows);
    var x = video.width() * (frame % frames_per_row);
    var y = video.height() * Math.floor(frame / frames_per_row);
    var position = "-" + x + "px -" + y + "px";
    video.css('background-position', position);
  }

  var nextFrame = function() {
    if (current_frame == 90)
      $('.steps .launch').fadeIn(900);
    if (current_frame == 250)
      $('.steps .share').fadeIn(900);
    if (current_frame == 410)
      $('.steps .pair').fadeIn(900);

    nextFrameFor(video_linux, 12, 465, 0);
    nextFrameFor(video_macos, 6,  231, 234);

    current_frame += 1;
    if (current_frame >= 465)
      clearTimeout(timer);
  };

  var startPlayback = function() {
    timer = setInterval(nextFrame, 33);
  };

  $("<img src='/img/video_linux.png' />").load(function() {
    $("<img src='/img/video_macos.png' />").load(function() {
      video_linux.css('background-image', "url('/img/video_linux.png')");
      video_macos.css('background-image', "url('/img/video_macos.png')");
      setTimeout(startPlayback, 2000);
    });
  });
});
