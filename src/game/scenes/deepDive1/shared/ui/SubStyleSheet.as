package game.scenes.deepDive1.shared.ui
{
	import flash.text.StyleSheet;
	
	public class SubStyleSheet extends StyleSheet
	{
		public function SubStyleSheet()
		{
			// TEXT
			var styleObj:Object = new Object();
			styleObj.fontFamily = "Futura";
			styleObj.fontWeight = "bold";
			styleObj.fontSize = 16;
			styleObj.color = "#47FFD5"; 
			this.setStyle(".text", styleObj); 
		}
	}
}