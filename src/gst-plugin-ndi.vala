const Gst.PluginDesc gst_plugin_desc = {
    1, 14,
    "ndi",
    "NewTek NDI Plugin",
    plugin_init,
    "0.10",
    "LGPL",
    "gst-plugin-ndi",
    "gst-plugin-ndi",
    "https://github.com/davidmhewitt/gst-plugin-ndi"
};

public static bool plugin_init (Gst.Plugin p) {
    Gst.Element.register (p, "ndisink", Gst.Rank.NONE, typeof(Gst.PluginNDI.Sink));
    return true;
}
