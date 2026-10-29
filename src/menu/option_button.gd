# MileTux

# Option Button - A simple button that automatically adds / removes an icon
# Copyright (C) 2026 Sophie Ball <sophieballvaesea@proton.me>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the license or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should've received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

extends Button

func _ready() -> void:
	if button_pressed:
		set_button_icon(load("res://data/images/objects/coin/coin-0.png"))
	else:
		icon = null

func _process(_delta: float) -> void:
	if button_pressed:
		set_button_icon(load("res://data/images/objects/coin/coin-0.png"))
	else:
		icon = null
