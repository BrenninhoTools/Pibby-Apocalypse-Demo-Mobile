package;

#if ASTC_TEXTURES
import flixel.FlxG;
import haxe.io.Bytes;
import lime.graphics.opengl.GL;
import lime.utils.UInt8Array;
import openfl.display.BitmapData;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.Texture;

/**
 * Uploads .astc files (made by tools/convert_astc.py) straight to the GPU, so
 * the texture never exists as an uncompressed RGBA bitmap in RAM.
 *
 * The returned BitmapData is texture-backed (readable = false, no `image`), exactly
 * like the ones Paths.returnGraphic already makes for GPU caching, so it can be
 * drawn but its pixels can't be read back.
 */
class AstcTexture
{
	static inline var MAGIC:Int = 0x5CA1AB13;
	static inline var HEADER_SIZE:Int = 16;

	static var _supported:Null<Bool> = null;

	/** True if the GPU exposes KHR_texture_compression_astc_ldr. Needs a live GL context, so it's checked lazily. */
	public static var supported(get, never):Bool;

	static function get_supported():Bool
	{
		if (_supported == null)
		{
			_supported = false;
			try
			{
				var extensions = GL.getSupportedExtensions();
				if (extensions != null)
				{
					for (extension in extensions)
					{
						if (extension.toLowerCase().indexOf('texture_compression_astc') != -1)
						{
							_supported = true;
							break;
						}
					}
				}
			}
			catch (e:Dynamic) {}
			trace('ASTC textures ${_supported ? "supported" : "NOT supported, using PNGs"}');
		}
		return _supported;
	}

	/** COMPRESSED_RGBA_ASTC_{x}x{y}_KHR, or 0 for a block size GL doesn't have. */
	static function glFormat(blockX:Int, blockY:Int):Int
	{
		return switch ([blockX, blockY])
		{
			case [4, 4]: 0x93B0;
			case [5, 4]: 0x93B1;
			case [5, 5]: 0x93B2;
			case [6, 5]: 0x93B3;
			case [6, 6]: 0x93B4;
			case [8, 5]: 0x93B5;
			case [8, 6]: 0x93B6;
			case [8, 8]: 0x93B7;
			case [10, 5]: 0x93B8;
			case [10, 6]: 0x93B9;
			case [10, 8]: 0x93BA;
			case [10, 10]: 0x93BB;
			case [12, 10]: 0x93BC;
			case [12, 12]: 0x93BD;
			default: 0;
		}
	}

	/** Returns null on any problem, so the caller can fall back to the PNG. */
	public static function load(bytes:Bytes):Null<BitmapData>
	{
		if (bytes == null || bytes.length < HEADER_SIZE || bytes.getInt32(0) != MAGIC)
			return null;

		var blockX = bytes.get(4);
		var blockY = bytes.get(5);
		var width = bytes.get(7) | (bytes.get(8) << 8) | (bytes.get(9) << 16);
		var height = bytes.get(10) | (bytes.get(11) << 8) | (bytes.get(12) << 16);
		var format = glFormat(blockX, blockY);

		// 2D only, every ASTC block is 16 bytes
		if (bytes.get(6) != 1 || format == 0 || width <= 0 || height <= 0)
			return null;

		var dataSize = Math.ceil(width / blockX) * Math.ceil(height / blockY) * 16;
		if (bytes.length - HEADER_SIZE < dataSize)
			return null;

		var context = FlxG.stage.context3D;
		if (context == null)
			return null;

		// A 1x1 texture so OpenFL doesn't allocate width*height*4 bytes of RGBA that we'd throw away
		// right after; the real storage comes from compressedTexImage2D below.
		var texture:Texture = context.createTexture(1, 1, Context3DTextureFormat.BGRA, false);

		@:privateAccess
		{
			context.__bindGLTexture2D(texture.__textureID);

			while (GL.getError() != GL.NO_ERROR) {} // don't blame ourselves for someone else's error
			GL.compressedTexImage2D(GL.TEXTURE_2D, 0, format, width, height, 0, dataSize, new UInt8Array(bytes, HEADER_SIZE, dataSize));
			var failed = GL.getError() != GL.NO_ERROR;

			if (!failed)
			{
				GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
				GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
				GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
				GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
			}
			context.__bindGLTexture2D(null);

			if (failed)
			{
				texture.dispose();
				return null;
			}

			texture.__width = width;
			texture.__height = height;
		}

		return BitmapData.fromTexture(texture);
	}
}
#end
