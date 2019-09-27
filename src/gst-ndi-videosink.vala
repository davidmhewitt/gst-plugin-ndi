namespace Gst.PluginNDI {
    class VideoSink : Gst.Video.Sink {
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

        construct {
            NDI.initialize ();
        }
    }
}
