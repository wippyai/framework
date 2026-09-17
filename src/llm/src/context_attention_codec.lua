local codec_v2 = require("codec_v2")
local codec_v34 = require("codec_v34")

return {
    ATTENTION_V2_LIMITS = codec_v2.ATTENTION_V2_LIMITS,
    canonical_json = codec_v2.canonical_json,
    expand_attention_v2 = codec_v2.expand_attention_v2,
    expand_attention_v3 = codec_v34.expand_attention_v3,
    expand_attention_v4 = codec_v34.expand_attention_v4,
    valid_attention_selection = codec_v34.valid_attention_selection,
}
