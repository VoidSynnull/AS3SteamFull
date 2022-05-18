package game.scenes.virusHunter.shared.ui
{
	import flash.text.StyleSheet;
	
	public class ShipStyleSheet extends StyleSheet
	{
		public function ShipStyleSheet()
		{
			// TITLES
			var styleObj:Object = new Object();
			styleObj.fontFamily = "Futura";
			styleObj.fontWeight = "bold";
			styleObj.fontSize = 21;
			styleObj.color = "#DA47FF"; 
			this.setStyle(".title", styleObj); 
			
			// TEXT
			styleObj = new Object();
			styleObj.fontFamily = "Futura";
			styleObj.fontWeight = "bold";
			styleObj.fontSize = 16;
			styleObj.color = "#47FFD5"; 
			this.setStyle(".text", styleObj); 
		}
	}
}