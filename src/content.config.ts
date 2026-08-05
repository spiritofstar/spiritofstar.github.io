import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const posts = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/posts' }),
  schema: z.object({
    title: z.string(),
    subtitle: z.string().optional(),
    author: z.string().optional(),
    date: z.string().optional(),
    categories: z.array(z.string()).default([]),
    // Legacy Pandoc/Quarto formatting block — accepted and ignored.
    format: z.any().optional(),
  }),
});

export const collections = { posts };
