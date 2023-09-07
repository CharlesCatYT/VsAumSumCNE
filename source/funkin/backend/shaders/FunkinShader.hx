package funkin.backend.shaders;

import haxe.Exception;
import hscript.IHScriptCustomBehaviour;
import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display3D.Program3D;
import flixel.system.FlxAssets.FlxShader;

import openfl.display.BitmapData;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.ShaderInput;
import lime.utils.Float32Array;

using StringTools;

import openfl.display.ShaderParameter;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;

@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
class FunkinShader extends FlxShader implements IHScriptCustomBehaviour {
	private static var __instanceFields = Type.getInstanceFields(FunkinShader);

	/**
	 * Creates a new shader from the specified fragment and vertex source.
	 * Accepts `#pragma header`.
	 * @param frag Fragment source (pass `null` to use default)
	 * @param vert Vertex source (pass `null` to use default)
	 */
	public override function new(frag:String, vert:String) {
		if (frag == null) frag = ShaderTemplates.defaultFragmentSource;
		if (vert == null) vert = ShaderTemplates.defaultVertexSource;
		this.glFragmentSource = frag;
		this.glVertexSource = vert;

		super();
	}

	@:noCompletion override private function set_glFragmentSource(value:String):String
	{
		if(value == null)
			value = ShaderTemplates.defaultFragmentSource;
		value = value.replace("#pragma header", ShaderTemplates.fragHeader).replace("#pragma body", ShaderTemplates.fragBody);
		if (value != __glFragmentSource)
		{
			__glSourceDirty = true;
		}

		return __glFragmentSource = value;
	}

	@:noCompletion override private function set_glVertexSource(value:String):String
	{
		if(value == null)
			value = ShaderTemplates.defaultVertexSource;
		value = value.replace("#pragma header", ShaderTemplates.vertHeader).replace("#pragma body", ShaderTemplates.vertBody);
		if (value != __glVertexSource)
		{
			__glSourceDirty = true;
		}

		return __glVertexSource = value;
	}

	public function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_${name}')) {
			return Reflect.getProperty(this, name);
		}
		if (!Reflect.hasField(data, name)) return null;
		var field = Reflect.field(data, name);
		var cl = Type.getClassName(Type.getClass(field));

		// cant do "field is ShaderInput" for some reason
		if (cl.startsWith("openfl.display.ShaderParameter")) {
			var sp = cast(field, ShaderParameter<Dynamic>);
			@:privateAccess
			return (sp.__length > 1) ? sp.value : sp.value[0];
		} else if (cl.startsWith("openfl.display.ShaderInput")) {
			var si = cast(field, ShaderInput<Dynamic>);
			return si.input;
		}
		return field;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_${name}')) {
			Reflect.setProperty(this, name, val);
			return val;
		}

		if (!Reflect.hasField(data, name)) {
			Reflect.setField(data, name, val);
			return val;
		} else {
			var field = Reflect.field(data, name);
			var cl = Type.getClassName(Type.getClass(field));
			// cant do "field is ShaderInput" for some reason
			if (cl.startsWith("openfl.display.ShaderParameter")) {
				@:privateAccess
				if (field.__length <= 1) {
					// that means we wait for a single number, instead of an array
					@:privateAccess
					if (field.__isInt && !(val is Int)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Int');
						return null;
					} else
					@:privateAccess
					if (field.__isBool && !(val is Bool)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Bool');
						return null;
					} else
					@:privateAccess
					if (field.__isFloat && !(val is Float)) {
						throw new ShaderTypeException(name, Type.getClass(val), 'Float');
						return null;
					}
					return field.value = [val];
				} else {
					if (!(val is Array)) {
						throw new ShaderTypeException(name, Type.getClass(val), Array);
						return null;
					}
					return field.value = val;
				}
			} else if (cl.startsWith("openfl.display.ShaderInput")) {
				// shader input!!
				if (!(val is BitmapData)) {
					throw new ShaderTypeException(name, Type.getClass(val), BitmapData);
					return null;
				}
				field.input = cast val;
			}
		}

		return val;
	}
}

class ShaderTemplates {
	public static final fragHeader:String = "varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;
uniform sampler2D bitmap;

uniform bool hasTransform;
uniform bool hasColorTransform;

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
{
	vec4 color = texture2D(bitmap, coord);
	if (!hasTransform)
	{
		return color;
	}

	if (color.a == 0.0)
	{
		return vec4(0.0, 0.0, 0.0, 0.0);
	}

	if (!hasColorTransform)
	{
		return color * openfl_Alphav;
	}

	color = vec4(color.rgb / color.a, color.a);

	mat4 colorMultiplier = mat4(0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = openfl_ColorMultiplierv.w;

	color = clamp(openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

	if (color.a > 0.0)
	{
		return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

uniform vec4 _camSize;

float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec2 getCamPos(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, size.x, size.x + size.z, 0.0, 1.0), map(pos.y, size.y, size.y + size.w, 0.0, 1.0));
}
vec2 camToOg(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, 0.0, 1.0, size.x, size.x + size.z), map(pos.y, 0.0, 1.0, size.y, size.y + size.w));
}
vec4 textureCam(sampler2D bitmap, vec2 pos) {
	return flixel_texture2D(bitmap, camToOg(pos));
}";

	public static final fragBody:String = "vec4 color = texture2D (bitmap, openfl_TextureCoordv);

if (color.a == 0.0) {

	gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);

} else if (openfl_HasColorTransform) {

	color = vec4 (color.rgb / color.a, color.a);

	mat4 colorMultiplier = mat4 (0);
	colorMultiplier[0][0] = openfl_ColorMultiplierv.x;
	colorMultiplier[1][1] = openfl_ColorMultiplierv.y;
	colorMultiplier[2][2] = openfl_ColorMultiplierv.z;
	colorMultiplier[3][3] = 1.0; // openfl_ColorMultiplierv.w;

	color = clamp (openfl_ColorOffsetv + (color * colorMultiplier), 0.0, 1.0);

	if (color.a > 0.0) {

		gl_FragColor = vec4 (color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);

	} else {

		gl_FragColor = vec4 (0.0, 0.0, 0.0, 0.0);

	}

} else {

	gl_FragColor = color * openfl_Alphav;

}";
	public static final vertHeader:String = "attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;";

	public static final vertBody:String = "openfl_Alphav = openfl_Alpha;
openfl_TextureCoordv = openfl_TextureCoord;

if (openfl_HasColorTransform) {

	openfl_ColorMultiplierv = openfl_ColorMultiplier;
	openfl_ColorOffsetv = openfl_ColorOffset / 255.0;

}

gl_Position = openfl_Matrix * openfl_Position;";


	public static final defaultVertexSource:String = "#pragma header

attribute float alpha;
attribute vec4 colorMultiplier;
attribute vec4 colorOffset;
uniform bool hasColorTransform;

void main(void)
{
	#pragma body

	openfl_Alphav = openfl_Alpha * alpha;

	if (hasColorTransform)
	{
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = colorMultiplier;
	}
}";


	// TODO: camera stuff
	public static final defaultFragmentSource:String = "#pragma header

void main(void)
{
	gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
}";
}

class ShaderTypeException extends Exception {
	var has:Class<Dynamic>;
	var want:Class<Dynamic>;
	var name:String;

	public function new(name:String, has:Class<Dynamic>, want:Dynamic) {
		this.has = has;
		this.want = want;
		this.name = name;
		super('ShaderTypeException - Tried to set the shader uniform "${name}" as a ${Type.getClassName(has)}, but the shader uniform is a ${Std.string(want)}.');
	}
}