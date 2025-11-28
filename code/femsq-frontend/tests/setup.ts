/**
 * Setup file for Vitest tests.
 * This file runs before all tests.
 */

import { vi } from 'vitest';

// Mock window.URL methods
global.URL.createObjectURL = vi.fn(() => 'mock-url');
global.URL.revokeObjectURL = vi.fn();

// Mock window.open
global.window.open = vi.fn();

// Mock fetch if needed
global.fetch = vi.fn();
