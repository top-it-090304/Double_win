shader_type canvas_item;
render_mode unshaded;

/* Иконка с зелёным кастом: гасим зелёный канал относительно красного, тёмним синий,
   затем красим в насыщенное золото/жёлтый по яркости формы. */

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 c = tex.rgb;

	float excess_g = max(0.0, c.g - c.r * 0.88);
	c.g -= excess_g * 0.92;
	c.r = min(1.0, c.r + excess_g * 0.42);
	c.b *= 0.2;
	c = clamp(c, vec3(0.0), vec3(1.0));

	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	float peak = max(c.r, max(c.g, c.b));
	// Больше опоры на светлые пиксели + общий подъём яркости
	float shape = clamp(mix(luma, peak, 0.62) * 1.52 + 0.06, 0.0, 1.0);
	shape = pow(shape, 0.82);

	// Светлое золото (#FFD700-стиль), не грязно-жёлтое
	vec3 gold = vec3(1.0, 0.86, 0.28);
	vec3 out_rgb = gold * shape * 1.12;
	out_rgb = clamp(out_rgb, vec3(0.0), vec3(1.0));

	COLOR = vec4(out_rgb, tex.a);
}
