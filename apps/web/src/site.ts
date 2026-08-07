export const site = {
	name: "Matthew Johnston",
	wordmark: "mattpjohnston",
	description:
		"Infrastructure engineer in Northern Ireland, working in on-premises data centres and cloud environments.",
	email: "matt@mpjohnston.com",
	links: [
		{ label: "GitHub", href: "https://github.com/mattpjohnston" },
		{ label: "LinkedIn", href: "https://www.linkedin.com/in/mattpjohnston/" },
	],
} as const;

export const nav = [
	{ name: "Platform", path: "/projects/" },
	{ name: "Writing", path: "/blog/" },
] as const;
