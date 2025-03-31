/*
 * KZones - KWin script for Windows-like zone based window tiling
 * Copyright (C) 2023-2024
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

// This file contains utility functions for the configuration UI

function setupAdvancedEdgeSnappingControls(enableEdgeSnapping, enableAdvancedEdgeSnapping, edgeSnappingTriggerDistance) {
    // Update the enabled state of the Advanced Edge Snapping checkbox based on Edge Snapping state
    function updateAdvancedEdgeSnappingState() {
        enableAdvancedEdgeSnapping.enabled = enableEdgeSnapping.checked;
        edgeSnappingTriggerDistance.enabled = enableEdgeSnapping.checked && !enableAdvancedEdgeSnapping.checked;
    }
    
    // Connect signals to update UI state when checkboxes change
    enableEdgeSnapping.toggled.connect(updateAdvancedEdgeSnappingState);
    enableAdvancedEdgeSnapping.toggled.connect(updateAdvancedEdgeSnappingState);
    
    // Initial update
    updateAdvancedEdgeSnappingState();
} 