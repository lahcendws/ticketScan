---
name: TicketScan
description: Mobile ticket validation app for event attendees
colors:
  primary: "#4A90E2"
  primary-dark: "#1E88E5"
  primary-light: "#E3F2FD"
  secondary: "#50E3C2"
  secondary-dark: "#26A69A"
  secondary-light: "#E0F2F1"
  accent: "#FF6B6B"
  accent-dark: "#FF5252"
  accent-light: "#FFCCBC"
  background: "#F8F9FA"
  surface: "#FFFFFF"
  card: "#FFFFFF"
  dark-background: "#1A1A2E"
  dark-surface: "#16213E"
  dark-card: "#0F3460"
  text-primary: "#2C3E50"
  text-secondary: "#7F8C8D"
  dark-text-primary: "#ECF0F1"
  dark-text-secondary: "#BDC3C7"
  success: "#27AE60"
  warning: "#F39C12"
  error: "#E74C3C"
  error-dark: "#C0392B"
typography:
  display:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "clamp(2rem, 5vw, 3.5rem)"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.5px
  headline:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "clamp(1.75rem, 4vw, 2.75rem)"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: -0.25px
  title:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "clamp(1.25rem, 3vw, 2rem)"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0px
  body:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "clamp(1rem, 2.5vw, 1.5rem)"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: 0px
  label:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "clamp(0.75rem, 2vw, 1.125rem)"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: 0.5px
  button:
    fontFamily: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    fontSize: "clamp(0.875rem, 2.25vw, 1.375rem)"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0px
rounded:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg} {spacing.xl}"
    height: "50px"
  button-secondary:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg} {spacing.xl}"
    height: "50px"
  button-accent:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg} {spacing.xl}"
    height: "50px"
  button-outline-primary:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    rounded: "{rounded.md}"
    padding: "{spacing.lg} {spacing.xl}"
    height: "50px"
    borderWidth: "2px"
    borderColor: "{colors.primary}"
  input-field:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "{spacing.md} {spacing.lg}"
    height: "50px"
    borderWidth: "1px"
    borderColor: "{colors.text-secondary}"
  input-field-focused:
    borderColor: "{colors.primary}"
    borderWidth: "2px"
  card:
    backgroundColor: "{colors.card}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
  card-elevated:
    backgroundColor: "{colors.card}"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
    shadow: "0 4px 12px rgba(0,0,0,0.08)"
  navigation-item:
    backgroundColor: "transparent"
    textColor: "{colors.text-secondary}"
    padding: "{spacing.md}"
  navigation-item-active:
    backgroundColor: "transparent"
    textColor: "{colors.primary}"
    padding: "{spacing.md}"
  badge:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.surface}"
    rounded: "{rounded.xs}"
    padding: "{spacing.xs} {spacing.sm}"
    fontSize: "0.75rem"
  badge-outline:
    backgroundColor: "transparent"
    textColor: "{colors.accent}"
    rounded: "{rounded.xs}"
    padding: "{spacing.xs} {spacing.sm}"
    borderWidth: "1px"
    borderColor: "{colors.accent}"
---

# Design System: TicketScan

## Overview

**Creative North Star: "The Accessible Event Companion"**

TicketScan embodies the philosophy of democratizing event access through intuitive, mobile-first design. Rather than relying on expensive specialized hardware, the app transforms everyday smartphones into powerful ticket validation tools. The design prioritizes clarity, speed, and reliability—essential qualities for high-pressure event entry scenarios where split-second decisions impact attendee experience.

The visual language balances professionalism with approachability, using a calm blue primary palette that conveys trust and security, complemented by vibrant teal and coral accents that guide attention to critical actions. Typography is clean and highly legible, ensuring information is readable at a glance even in varying lighting conditions. Interactive elements provide clear tactile feedback, building user confidence in each validation action.

**Key Characteristics:**
- Mobile-first, touch-optimized interface designed for quick interactions
- High-contrast, legible typography for readability in varied lighting
- Consistent spacing and alignment for predictable touch targets
- Clear visual hierarchy that guides users to primary actions
- Subtle elevation and shadow use for depth without visual clutter
- Accessible color combinations meeting WCAG AA standards
- Responsive layout adapting to various smartphone screen sizes

## Colors

### Primary
**Trustworthy Blue** (#4A90E2 / oklch(69% 0.19 254)): Used for primary buttons, active navigation links, link text, and key interactive elements. This blue establishes the app's identity and conveys reliability and security—essential for ticket validation where users need to trust the system.

### Secondary
**Fresh Teal** (#50E3C2 / oklch(78% 0.14 164)): Applied to secondary actions, status indicators, and supplementary information. Provides visual variety while maintaining harmony with the primary blue. Used for alternative action buttons and non-critical interactive elements.

### Accent
**Attention Coral** (#FF6B6B / oklch(63% 0.21 24)): Reserved for critical alerts, error states, and elements requiring immediate attention. Used sparingly to maintain impact—appears in warning banners, error messages, and urgent call-to-action buttons.

### Neutral
**Clean White** (#FFFFFF / oklch(98% 0.00 0)): Primary background color for cards, modals, and content containers. Creates a clean, spacious feel that enhances readability and focuses attention on content.

**Soft Gray** (#F8F9FA / oklch(97% 0.00 200)): Application background color, providing subtle contrast against white content areas while maintaining a light, airy feel.

**Medium Gray** (#7F8C8D / oklch(55% 0.02 240)): Used for secondary text, placeholder content, and disabled states. Ensures proper visual hierarchy and accessibility.

**Dark Blue** (#2C3E50 / oklch(32% 0.05 250)): Primary text color for body content, ensuring excellent readability on light backgrounds.

### Status Colors
**Success Green** (#27AE60 / oklch(58% 0.15 142)): Indicates successful operations, validated tickets, and positive confirmations.

**Warning Orange** (#F39C12 / oklch(72% 0.18 45)): Used for expiring warranties, pending actions, and non-critical notices requiring user attention.

**Error Red** (#E74C3C / oklch(44% 0.18 22)): Applied to validation errors, failed operations, and destructive actions like deletion.

### Dark Mode
In dark mode, the color palette inverts appropriately:
- Background shifts to deep navy (#1A1A2E)
- Surfaces become darker blue-gray (#16213E and #0F3460)
- Text transitions to light gray-white (#ECF0F1 and #BDC3C7)
- Primary and accent colors maintain their vibrancy for consistent identification

## Typography

**Display Font:** Inter (with system fallbacks)
**Body Font:** Inter (with system fallbacks)
**Label/Mono Font:** Inter (with system fallbacks)

**Character:** Clean, modern, and highly legible. Inter was chosen for its excellent readability on mobile screens, open apertures that prevent character confusion at small sizes, and neutral personality that lets content shine without typographic distraction.

### Hierarchy
- **Display** (700, clamp(2rem, 5vw, 3.5rem), 1.2): App titles, major section headers, promotional headlines
- **Headline** (600, clamp(1.75rem, 4vw, 2.75rem), 1.3): Page titles, important section headings
- **Title** (600, clamp(1.25rem, 3vw, 2rem), 1.4): Card headers, list item titles, form section labels
- **Body** (400, clamp(1rem, 2.5vw, 1.5rem), 1.6): Paragraph text, descriptive content, form field labels
- **Label** (500, clamp(0.75rem, 2vw, 1.125rem), 1.4): Form field labels, button text, navigation items, status tags
- **Button** (600, clamp(0.875rem, 2.25vw, 1.375rem), 1.4): Button text, ensuring consistent weight and sizing across interactive elements

## Layout

TicketScan employs a fluid, mobile-optimized layout system based on an 8px grid. All spacing, dimensions, and positioning adhere to multiples of 4px and 8px for visual harmony and development consistency.

The layout prioritizes vertical scrolling for content presentation, with full-width containers that maximize screen real estate on mobile devices. Content areas feature generous padding (typically 16-24px) to prevent edge-touching and improve touch accuracy.

Key layout principles:
- **Full-width containers**: Most content stretches edge-to-edge with appropriate padding
- **Consistent breakpoints**: Design adapts seamlessly from small (320px) to large (414px+) smartphone screens
- **Touchable targets**: All interactive elements maintain minimum 48x48px touch area per accessibility guidelines
- **Vertical rhythm**: Consistent spacing between elements creates predictable scanning patterns
- **Card-based organization**: Information is grouped in elevated cards with consistent spacing (12-16px margin bottom)

## Elevation & Depth

TicketScan uses a subtle, purposeful elevation system to convey hierarchy and interactivity without visual clutter. Shadows are employed sparingly to lift important elements and provide tactile feedback.

**Elevation Philosophy:** Lifted-by-interaction. Surfaces are primarily flat at rest, with elevation appearing as a direct response to user interaction (press, focus) or to indicate importance (cards, dialogs, floating action buttons).

### Shadow Vocabulary (if applicable)
- **Subtle Elevation** (`0 2px 6px rgba(0,0,0,0.08)`): Applied to cards and containers for subtle depth
- **Focus Elevation** (`0 4px 12px rgba(0,0,0,0.12)`): Used on pressed/focused buttons and interactive elements
- **Modal Elevation** (`0 8px 24px rgba(0,0,0,0.16)`): Applied to dialogs, modals, and popups for clear separation from background
- **Navigation Elevation** (`0 4px 8px rgba(0,0,0,0.1)`): Used on bottom navigation bar for subtle separation from content

## Shapes

TicketScan utilizes a consistent radius language based on rounded rectangles, creating a modern, approachable feel that balances softness with precision.

**Form Language:** Uniformly rounded with purposeful variation. All corners use the same radius values within a given element type, creating visual consistency. Radius values increase with element prominence and size.

- **Small elements** (buttons, chips, avatars): 8px radius (sm)
- **Medium elements** (input fields, cards): 12px radius (md)
- **Large elements** (dialogs, modals): 16px radius (lg)
- **Extra-large elements**: 20px radius (xl)

Borders are used sparingly—primarily on input fields and cards—with a preference for using elevation and background color changes to define clipping rather than visible strokes where possible.

## Components

### Buttons
- **Shape:** Uniformly rounded with 12px radius (md)
- **Primary:** Trustworthy Blue background (#4A90E2), white text, 24px horizontal padding, 12px vertical padding, 50px fixed height
- **Secondary:** Fresh Teal background (#50E3C2), white text, identical sizing to primary
- **Accent:** Attention Coral background (#FF6B6B), white text, identical sizing to primary
- **Outline Primary:** Transparent background, Trustworthy Blue text (#4A90E2), 2px border in Trustworthy Blue, otherwise identical to primary
- **Hover / Focus:** All button variants lift slightly on press/focus (0 4px 12px rgba(0,0,0,0.12)) and scale down subtly (98%)
- **Disabled:** 30% opacity background, 40% opacity text, no lift interaction

### Chips / Tags
- **Style:** Solid background with Trustworthy Blue or corresponding status color, white text for primary accents
- **Alternative Style:** Transparent background, colored text matching status, 1px border in corresponding color
- **Radius:** 6px (xs) for compact tag appearance
- **Padding:** 6px horizontal, 4px vertical
- **Text:** Label weight (500), clamp(0.75rem, 2vw, 1.125rem) font size

### Cards / Containers
- **Corner Style:** 16px radius (lg) for most cards, creating a pronounced rounded feel
- **Background:** White surface (#FFFFFF) in light mode, dark surface colors in dark mode
- **Shadow Strategy:** Reference Elevation section - subtle elevation (0 2px 6px rgba(0,0,0,0.08)) for standard cards
- **Border:** Typically none; shape and elevation define the container
- **Internal Padding:** 24px on all sides (lg) for content breathing room

### Inputs / Fields
- **Style:** White background (#FFFFFF), Trustworthy Blue or text-secondary text color
- **Radius:** 12px radius (md) consistent with button sizing
- **Border:** 1px solid in text-secondary (#7F8C8D) for standard state
- **Focus:** 2px solid in primary color (#4A90E2) with subtle lift elevation
- **Error:** 2px solid in error color (#E74C3C)
- **Disabled:** Background in light gray (#F8F9FA at 50% opacity), text in text-secondary at 40% opacity
- **Content Padding:** 16px horizontal, 12px vertical (md and sm)

### Navigation
- **Style:** Bottom navigation bar with transparent background in light mode, dark surface in dark mode
- **Typography:** Label weight (500), clamp(0.75rem, 2vw, 1.125rem) font size for destination labels
- **Default State:** Text-secondary color (#7F8C8D), 24px icon size
- **Active State:** Primary color (#4A90E2) for both icon and text, indicating current selection
- **Inactive State:** Text-secondary color (#7F8C8D) for both icon and text
- **Treatment:** No label shift on active state, icon and text transition together
- **Height:** 64px fixed height with 8px top padding
- **Elevation:** Subtle lift (0 4px 8px rgba(0,0,0,0.1)) to separate from content

### [Signature Component] Ticket Validation Interface
The ticket validation screen represents TicketScan's core functionality—a camera-focused interface designed for rapid ticket scanning in event environments.

- **Style:** Full-screen camera preview with overlay UI elements
- **Camera Feed:** Takes maximum available screen space behind UI elements
- **Overlay Controls:** Semi-transparent dark background (rgba(0,0,0,0.4)) for bottom action bar
- **Action Buttons:** Large, trustworthy blue primary buttons (minimum 60x60px touch target) for manual entry and flashlight toggle
- **Status Indicators:** Prominent text at top showing validation status in large, legible typography
- **Frame Guide:** Optional rectangular guide in trustworthy blue with dashed strokes to help align tickets
- **Feedback System:** Immediate visual confirmation (green check) or error (red X) with corresponding color flash and haptic feedback

## Do's and Don'ts

### Do:
- **Do** use the Trustworthy Blue (#4A90E2) for primary actions and key interactive elements to maintain visual consistency and brand recognition
- **Do** maintain minimum 48x48px touch targets for all interactive elements to ensure accessibility
- **Do** apply 16px radius (lg) to cards and containers for a consistent, modern feel
- **Do** use the 8px grid system for all spacing, positioning, and sizing decisions
- **Do** elevate interactive elements on press/focus with subtle shadow (0 4px 12px rgba(0,0,0,0.12)) to provide tactile feedback
- **Do** use Fresh Teal (#50E3C2) for secondary actions and supplementary information
- **Do** reserve Attention Coral (#FF6B6B) for error states, warnings, and critical alerts requiring immediate attention
- **Do** maintain consistent vertical rhythm with 12-16px spacing between related elements and 24px between distinct sections

### Don't:
- **Don't** use pure black (#000000) for text—use Dark Blue (#2C3E50) in light mode and light gray (#ECF0F1) in dark mode for better readability
- **Don't** create touch targets smaller than 48x48px, as this impairs usability especially in mobile contexts
- **Don't** mix different radius values within the same element type—inconsistent rounding creates visual noise
- **Don't** use borders as the primary means of defining element boundaries—prefer elevation and background color changes
- **Don't** apply elevation to static elements that don't change state—reserve lift for interactive components
- **Don't** use the Accent Coral (#FF6B6B) for primary actions or frequent interactive elements—its impact diminishes with overuse
- **Don't** reduce padding below 8px on any side, as this creates cramped layouts and increases risk of accidental activation
- **Don't** use font weights below 400 for body text—light weights impair readability on mobile screens