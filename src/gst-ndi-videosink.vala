namespace Gst.PluginNDI {
    class VideoSink : Gst.Video.Sink {

        private NDI.Send? sender;
        private NDI.VideoFrameV2 frame;
        private size_t buffer_size = 0;

        static construct {
            set_static_metadata (
                "NDI Video Sink",
                "Sink",
                "Stream video to an NDI network",
                "David Hewitt <davidmhewitt@gmail.com>"
            );

            var caps = new Gst.Caps.empty ();

            // Advertise support any video dimensions and frame rate
            var struc = new Gst.Structure (
                "video/x-raw",
                "width", typeof (Gst.IntRange), 0, int32.MAX,
                "height", typeof (Gst.IntRange), 0, int32.MAX,
                "framerate", typeof (Gst.FractionRange), 0, 1, int32.MAX, 1
            );

            // Advertise our supported pixel formats
            var list = GLib.Value (typeof (Gst.ValueList));
            Gst.ValueList.append_value (list, "UYVY");
            Gst.ValueList.append_value (list, "YV12");
            Gst.ValueList.append_value (list, "I420");
            Gst.ValueList.append_value (list, "NV12");
            Gst.ValueList.append_value (list, "BGRA");
            Gst.ValueList.append_value (list, "BGRx");
            Gst.ValueList.append_value (list, "RGBA");
            Gst.ValueList.append_value (list, "RGBx");

            struc.set_value ("format", list);

            caps.append_structure ((owned)struc);

            var sink_template = new Gst.PadTemplate (
                "sink",
                Gst.PadDirection.SINK,
                Gst.PadPresence.REQUEST,
                caps
            );

            add_pad_template (sink_template);
        }

        public override bool set_caps (Gst.Caps caps) {
            warning (caps.to_string ());

            unowned Gst.Structure struc = caps.get_structure (0);
            int width, height, frame_rate_n, frame_rate_d;
            if (!struc.get_int ("width", out width)) {
                return false;
            }

            if (!struc.get_int ("height", out height)) {
                return false;
            }

            if (struc.get_fraction ("framerate", out frame_rate_n, out frame_rate_d)) {
                frame.frame_rate_N = frame_rate_n;
                frame.frame_rate_D = frame_rate_d;
            }

            var format = struc.get_string ("format");
            if (format == null) {
                return false;
            }

            switch (format) {
                case "BGRA":
                    frame.pixel_format = NDI.FourCCPixelFormat.BGRA;
                    frame.line_stride_in_bytes = width * 4;
                    buffer_size = width * height * 4;
                    break;
                case "BGRx":
                    frame.pixel_format = NDI.FourCCPixelFormat.BGRX;
                    frame.line_stride_in_bytes = width * 4;
                    buffer_size = width * height * 4;
                    break;
                case "RGBA":
                    frame.pixel_format = NDI.FourCCPixelFormat.RGBA;
                    frame.line_stride_in_bytes = width * 4;
                    buffer_size = width * height * 4;
                    break;
                case "RGBx":
                    frame.pixel_format = NDI.FourCCPixelFormat.RGBX;
                    frame.line_stride_in_bytes = width * 4;
                    buffer_size = width * height * 4;
                    break;
                case "I420":
                    frame.pixel_format = NDI.FourCCPixelFormat.I420;
                    frame.line_stride_in_bytes = width;
                    buffer_size = width * height * 3;
                    break;
                case "NV12":
                    frame.pixel_format = NDI.FourCCPixelFormat.NV12;
                    frame.line_stride_in_bytes = width;
                    buffer_size = width * height * 3;
                    break;
                case "UYVY":
                    frame.pixel_format = NDI.FourCCPixelFormat.UYVY;
                    frame.line_stride_in_bytes = width * 2;
                    buffer_size = width * height * 2;
                    break;
                case "YV12":
                    frame.pixel_format = NDI.FourCCPixelFormat.YV12;
                    frame.line_stride_in_bytes = width;
                    buffer_size = width * height * 2;
                    break;
                default:
                    return false;
            }

            frame.xres = width;
            frame.yres = height;

            if (frame.data != null) {
                free (frame.data);
            }

            return base.set_caps (caps);
        }

        public override Gst.FlowReturn render (Gst.Buffer buffer) {
            buffer.extract_dup (0, buffer_size, out frame.data);
            sender.send_video_v2 (frame);
            free (frame.data);
            return Gst.FlowReturn.OK;
        }

        construct {
            NDI.initialize ();

            sender = NDI.Send.create ();
            frame = NDI.VideoFrameV2.create_default ();
        }
    }
}
