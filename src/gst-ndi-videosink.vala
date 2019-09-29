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

            var struc = new Gst.Structure (
                "video/x-raw",
                "width", typeof (Gst.IntRange), 0, int32.MAX,
                "height", typeof (Gst.IntRange), 0, int32.MAX,
                "framerate", typeof (Gst.FractionRange), 0, 1, int32.MAX, 1
            );

            var list = GLib.Value (typeof (Gst.ValueList));
            Gst.ValueList.append_value (list, "RGBA");
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

            frame.xres = width;
            frame.yres = height;

            frame.pixel_format = NDI.FourCCPixelFormat.RGBA;
            frame.line_stride_in_bytes = width * 4;
            buffer_size = width * height * 4;
            frame.data = malloc (buffer_size);

            return base.set_caps (caps);
        }

        public override Gst.FlowReturn render (Gst.Buffer buffer) {
            buffer.extract_dup (0, buffer_size, out frame.data);
            sender.send_video_v2 (frame);
            return Gst.FlowReturn.OK;
        }

        construct {
            NDI.initialize ();

            sender = NDI.Send.create ();
            frame = NDI.VideoFrameV2.create_default ();
        }
    }
}
