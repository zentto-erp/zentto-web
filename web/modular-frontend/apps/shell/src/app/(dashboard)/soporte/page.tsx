'use client';
import { useEffect } from 'react';

export default function SoporteRedirect() {
  useEffect(() => { window.open('https://docs.zentto.net/casos', '_blank'); }, []);
  return null;
}
