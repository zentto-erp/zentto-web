'use client';
import { useEffect } from 'react';

export default function DocsRedirect() {
  useEffect(() => { window.open('https://docs.zentto.net', '_blank'); }, []);
  return null;
}
