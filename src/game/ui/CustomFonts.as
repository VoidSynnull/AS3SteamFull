package game.ui
{
	import flash.text.Font;

	public class CustomFonts
	{
		[Embed(source="/../installed_fonts/TrueType/ExpletiveDeleted.ttf", fontName = "ExpletiveDeleted", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var ExpletiveDeletedFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(ExpletiveDeletedFont);
		
		public function CustomFonts() {}
	}
}