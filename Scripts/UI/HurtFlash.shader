shader_type canvas_item;

uniform float size_x = 0.01;
uniform float size_y = 0.01;
uniform float intensity = 1;

uniform sampler2D noise;

void fragment() {
	float alpha = COLOR.a * intensity;

	vec2 uv = SCREEN_UV;

	uv -= mod(uv,vec2(size_x,size_y))*alpha;

	vec2 noise_uv = SCREEN_UV;
	noise_uv.x *= 0.05;
	noise_uv.x += TIME;
	noise_uv.y += TIME;

	vec2 uv_r = uv;
	uv_r.x += (texture(noise, noise_uv+0.25).x-0.5)*0.75*alpha;
	uv_r.y += (texture(noise, noise_uv+0.25).y-0.5)*0.2*alpha;

	vec2 uv_g = uv;
	uv_g.x += (texture(noise, noise_uv).x-0.5)*0.75*alpha;
	uv_g.y += (texture(noise, noise_uv).y-0.5)*0.2*alpha;
	
	vec2 uv_b = uv;
	uv_b.x += (texture(noise, noise_uv-0.25).x-0.5)*0.75*alpha;
	uv_b.y += (texture(noise, noise_uv-0.25).y-0.5)*0.2*alpha;

	vec4 color = COLOR;

	COLOR.rgb = color.rgb * alpha;
	COLOR.r += textureLod(SCREEN_TEXTURE,uv_r,0.0).r * (1.0-alpha);
	COLOR.g += textureLod(SCREEN_TEXTURE,uv_g,0.0).g * (1.0-alpha);
	COLOR.b += textureLod(SCREEN_TEXTURE,uv_b,0.0).b * (1.0-alpha);
	COLOR.a = 1.0;
}
