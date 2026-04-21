/**
 * `@zentto/landing-kit/blog` — public exports.
 *
 * Uso:
 *   import { BlogIndex, BlogPostReader } from "@zentto/landing-kit/blog";
 */

export { BlogIndex, type BlogIndexProps } from "./BlogIndex";
export {
  BlogPostReader,
  type BlogPostReaderProps,
  type BlogPostFull,
} from "./BlogPostReader";
export {
  BlogBreadcrumbs,
  type BlogBreadcrumbsProps,
  type BlogBreadcrumbItem,
} from "./BlogBreadcrumbs";
export { BlogPagination, type BlogPaginationProps } from "./BlogPagination";
export {
  buildBlogIndexMetadata,
  buildBlogPostMetadata,
  type BuildBlogIndexMetadataOpts,
  type BuildBlogPostMetadataOpts,
} from "./blog-metadata";
