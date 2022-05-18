package game.ui
{
	import flash.text.Font;
	
	public class Fonts
	{
		
		[Embed(source="/../installed_fonts/TrueType/arial.ttf", fontName = "Arial", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var ArialFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(ArialFont);
		
		[Embed(source = "/../installed_fonts/TrueType/arialbd.ttf", fontName = "Arial Bold", mimeType = 'application/x-font-opentype', 
         embedAsCFF= "false")]
		public static var ArialBold:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(ArialBold);
		
		[Embed(source = "/../installed_fonts/TrueType/arialbi.ttf", fontName = "Arial Bold Italic", mimeType = 'application/x-font-opentype', 
         embedAsCFF= "false")]
		public static var ArialBoldItalic:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(ArialBoldItalic);
		
		[Embed(source = "/../installed_fonts/OpenType/Billy-Light.otf", fontName = "Billy Light", mimeType = 'application/x-font-opentype',  
		 unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E',
         embedAsCFF= "false")]
		public static var BillyLightFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(BillyLightFont);
		
		[Embed(source = "/../installed_fonts/OpenType/BillyBold.otf", fontName = "Billy Bold", mimeType = 'application/x-font-opentype',  
		 unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E,U+2731',
         embedAsCFF= "false")]
		public static var BillyBoldFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(BillyBoldFont);
		
		[Embed(source="/../installed_fonts/OpenType/BillySerif.otf", fontName="Billy Serif", mimeType="application/x-font-opentype", embedAsCFF="false")]
		public static var BillySerifFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(BillySerifFont);
		
		[Embed(source="/../installed_fonts/OpenType/ChaparralPro-Regular.otf", fontName = "Chaparral Pro", mimeType = 'application/x-font-opentype', embedAsCFF= "false")]
		public static var ChaparralPro:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(ChaparralPro);
		
		[Embed(source="/../installed_fonts/OpenType/PoplarStd.otf", fontName = "PoplarStd", mimeType="application/x-font-openType", embedAsCFF= "false")]
		public static var PoplarStd:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(PoplarStd);
		
		[Embed(source = "/../installed_fonts/TrueType/CreativeBlockBB.TTF", fontName = "CreativeBlock BB", mimeType = 'application/x-font-truetype',
		 unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E',
         embedAsCFF= "false")]
		public static var CBFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(CBFont);
		
		[Embed(source = "/../installed_fonts/TrueType/CreativeBlockBBBold.TTF", fontName = "CreativeBlock BB Bold", mimeType = 'application/x-font-truetype',
		 unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E',
         embedAsCFF= "false")]
		public static var CBBFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(CBBFont);
		
		// temporary (and benign) testing comment: Test that deploy.properties is no longer needed...take 2
		// TODO: figure out what these attributes do. unicodeRange? embedAsCFF? not all characters are being embedded properly
		// embedAsCFF means 'use Compact Font Format' and enables advanced formatting features of FTE such as bidirectional text, kerning, and ligatures.
		/*		[Embed(source="/../installed_fonts/OpenTypeghostkidaoe.ttf", fontName="GhostKid AOE", mimeType="application/x-font-truetype",  
		unicodeRange='U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E',
		embedAsCFF= "false")]*/
		[Embed(source="/../installed_fonts/TrueType/ghostkidaoe.ttf", fontName="GhostKid AOE", mimeType="application/x-font-truetype",  
		 embedAsCFF= "false")]
		public static var GhostKidFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(GhostKidFont);
		/* Nota bene: 
		the following embed of billy light.otf caused a compilation error: "unable to transcode font"
		
		In order to eliminate the error, I had to add an additional compiler argument to my project: -managers flash.fonts.AFEFontManager
		*/
		
		[Embed(source="/../installed_fonts/TrueType/verdana_1.ttf", fontName = "Verdana", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var VerdanaFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(VerdanaFont);
		
		[Embed(source="/../installed_fonts/TrueType/Futura_XBlk_BT_Extra_Black.ttf", fontName = "Futura", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var FuturaFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(FuturaFont);
		
		[Embed(source="/../installed_fonts/TrueType/FOXLB9_.TTF", fontName = "Foxley", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var FoxleyFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(FoxleyFont);
		
		[Embed(source="/../installed_fonts/TrueType/DIOGENES.ttf", fontName = "Diogenes", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var DiogenesFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(DiogenesFont);
		
		[Embed(source="/../installed_fonts/TrueType/WebLettererBB.TTF", fontName = "WebLetterer BB", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var WebLettererBBFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(WebLettererBBFont);

		[Embed(source="/../installed_fonts/TrueType/ExpletiveDeleted.ttf", fontName = "ExpletiveDeleted", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var ExpletiveDeletedFont:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(ExpletiveDeletedFont);
		
		[Embed(source="/../installed_fonts/TrueType/MVSansBold.ttf", fontName = "MVSans_Bold", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var MVSansBold:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(MVSansBold);
		
		[Embed(source="/../installed_fonts/TrueType/cour.ttf", fontName = "Courier", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var Courier:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(Courier);
		
		[Embed(source="/../installed_fonts/TrueType/courbd.ttf", fontName = "Courier Bold", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var CourierBold:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(CourierBold);
		
		[Embed(source="/../installed_fonts/TrueType/Modern Destronic.ttf", fontName = "Modern Destronic", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var ModernDestronic:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(ModernDestronic);
		
		[Embed(source="/../installed_fonts/TrueType/LCDMonoLight.ttf", fontName = "LCDMono", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var LCDMono:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(LCDMono);
		
		[Embed(source="/../installed_fonts/TrueType/Helvetica Bold.ttf", fontName = "Helvetica Bold", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var HelveticaBold:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(HelveticaBold);
		
		[Embed(source="/../installed_fonts/TrueType/GrilledCheeseBTNWide.ttf", fontName = "Grilled Cheese Wide", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var GrilledCheeseWide:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(GrilledCheeseWide);
		
		[Embed(source="/../installed_fonts/TrueType/OrangeKid.TTF", fontName = "Orange Kid", mimeType="application/x-font-trueType", embedAsCFF= "false")]
		public static var OrangeKid:Class; // note this class isn't ever referenced, but for you have to include it with an embed
		Font.registerFont(OrangeKid);
		
		
		
		
		public function Fonts() {}
	}
}