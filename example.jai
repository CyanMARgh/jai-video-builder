#import,file "video_builder.jai";
#import "Basic";

WIDTH, HEIGHT :: 1280, 720;

main :: () {
	gen_video();
	scaled_video();
}
scaled_video :: () {
	frame_0 := make_frame(WIDTH, HEIGHT); defer clear(frame_0);
	frame_1 := make_frame(WIDTH / 10, HEIGHT / 10); defer clear(frame_1);

	for check_time {
		ffmpeg := ffmpeg_start_rendering(WIDTH, HEIGHT, filename = "scaled.mp4");
		for i : 1..500 {
			fill_frame(*frame_0, xx i);
			ffmpeg_scale_and_send_frame(*ffmpeg, frame_0);
			print("% / 500\n", i);
		}
		for i : 1..500 {
			fill_frame(*frame_1, 50 + i / 10.);
			ffmpeg_scale_and_send_frame(*ffmpeg, frame_1);
			print("% / 500\n", i);
		}
		ffmpeg_end_rendering(*ffmpeg);		
	}
}

check_time : struct {};
for_expansion :: (o : type_of(check_time), $body : Code, flags : For_Flags) #expand {	
	`it, `it_index := 0;
	time_start := current_time_monotonic();
	defer {
		time_end := current_time_monotonic();
		print("time spent = %\n", to_float64_seconds(time_end - time_start));		
	}
	#insert body;
}
gen_video :: () {
	for check_time {
		ffmpeg, succes := ffmpeg_start_rendering(WIDTH, HEIGHT);
		if !succes {
			print("failed to call ffmpeg\n");
			exit(1);
		}
		for i : 1..1000 {
			fill_frame(*ffmpeg.buffer, xx i);
			ffmpeg_send_frame(*ffmpeg);
			print("% / 1000\n", i);
		}
		ffmpeg_end_rendering(*ffmpeg);
	}
}
fill_frame :: (using frame : *Frame, id : float) {
	i := 0;
	for y : 0..height-1 {
		for x : 0..width-1 {
			pixels[i] = xx ifx (cast(float)(x * x + y * y) > id * id) then 0xFFFFFFFF else 0xFF000000;
			i += 1;
		}
	}
}