#import "Process";
#import "Basic";
#import "File";
#import "stb_image_resize";

#if OS == .WINDOWS {
	#import "Windows";
} else {
	#import "POSIX";
}

FFMPEG :: struct {
	process : Process;
	buffer : Frame;
}
ffmpeg_start_rendering :: (width : int, height : int, fps := 60, filename := "output.mp4", path := ".", bitrate := 2500) -> FFMPEG, ok:bool {
	ffmpeg := FFMPEG.{
		buffer = make_frame(width, height)
	};

	make_directory_if_it_does_not_exist(path, true);
	success := create_process(*ffmpeg.process,
		"ffmpeg",
		"-loglevel", "verbose",
		"-y",
		"-f", "rawvideo",
		"-pix_fmt", "rgba",
		"-s", tprint("%x%", width, height),
		"-r", tprint("%", fps),
		"-i", "-",
		"-c:v", "libx264",
		"-vb", tprint("%k", bitrate),
		"-c:a", "aac",
		"-ab", "200k",
		"-pix_fmt", "yuv420p",
		tprint("%/%", path, filename),
		capture_and_return_output = true
	);
	return ffmpeg, success;
}
ffmpeg_end_rendering :: (ffmpeg : *FFMPEG) {
	#if OS == .WINDOWS {
		fclose(ffmpeg.process.input.handle); //not sure about this
	} else {
		close(ffmpeg.process.input.handle);
	}
	success, result := get_process_result(*ffmpeg.process);
	clear(ffmpeg.buffer);
}
ffmpeg_send_frame :: (ffmpeg : *FFMPEG) {
	ffmpeg_send_frame_helper(ffmpeg, ffmpeg.buffer);
}
ffmpeg_scale_and_send_frame :: (ffmpeg : *FFMPEG, input_frame : Frame) -> ok:bool {
	resized := input_frame;
	if ffmpeg.buffer.width != input_frame.width && ffmpeg.buffer.height != input_frame.height {		
		stbir_resize_uint8(
			xx input_frame.pixels, xx input_frame.width, xx input_frame.height, xx(input_frame.width * 4),
			xx ffmpeg.buffer.pixels, xx ffmpeg.buffer.width, xx ffmpeg.buffer.height, xx(ffmpeg.buffer.width * 4),
			4
		);
		resized = ffmpeg.buffer;
	}
	ffmpeg_send_frame_helper(ffmpeg, resized);
	return true;
}

ffmpeg_send_frame_helper :: (ffmpeg : *FFMPEG, frame : Frame) {
	bytes := frame.bytes;
	while bytes.count > 0 {
		succes, bytes_written := write_to_process(*ffmpeg.process, bytes);
		bytes.data += bytes_written;
		bytes.count -= bytes_written;
	}
}

Frame :: struct {
	width, height : int;
	bytecount : int;
	pixels : *u32;
	#place bytecount;
	bytes : []u8;
}
make_frame :: (width : int, height : int) -> Frame {
	return .{
		width = width,
		height = height,	
		bytes = NewArray(width * height * 4, u8)
	};
}
clear :: (using frame : Frame) {
	array_free(bytes);
}