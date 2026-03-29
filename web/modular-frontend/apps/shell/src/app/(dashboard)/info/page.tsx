'use client';
import { useEffect } from 'react';

export default function InfoRedirect() {
  useEffect(() => { window.open('https://zentto.net', '_blank'); }, []);
  return null;
}
