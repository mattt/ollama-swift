import Foundation
import Ollama

struct HexColorInput: Codable {
    let red: Double
    let green: Double
    let blue: Double
}

let hexColorTool = Tool<HexColorInput, String>(
    name: "rgb_to_hex",
    description: """
        Converts RGB components to a hexadecimal color string.

        The input is a JSON object with three floating-point numbers
        representing the red, green, and blue components of a color.
        The output is a string representing the color in hexadecimal format.

        Parameters are named red, green, and blue. 
        Values are floating-point numbers between 0.0 and 1.0.
        """,
    parameters: [
        "type": "object",
        "properties": [
            "red": [
                "type": "number",
                "description": "The red component of the color",
                "minimum": 0.0,
                "maximum": 1.0,
            ],
            "green": [
                "type": "number",
                "description": "The green component of the color",
                "minimum": 0.0,
                "maximum": 1.0,
            ],
            "blue": [
                "type": "number",
                "description": "The blue component of the color",
                "minimum": 0.0,
                "maximum": 1.0,
            ],
        ],
        "required": ["red", "green", "blue"],
    ]
) { (input) async throws -> String in
    let r = Int(round(input.red * 255))
    let g = Int(round(input.green * 255))
    let b = Int(round(input.blue * 255))
    return String(
        format: "#%02X%02X%02X",
        min(max(r, 0), 255),
        min(max(g, 0), 255),
        min(max(b, 0), 255)
    )
}
