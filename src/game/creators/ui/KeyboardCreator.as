package game.creators.ui
{
	import game.data.ui.ButtonData;

	public class KeyboardCreator
	{		
		public static function getLayout( layoutType:String ):Vector.<Vector.<ButtonData>>
		{
			var layout:Vector.<Vector.<ButtonData>> = new Vector.<Vector.<ButtonData>>();
			var keyRow:Vector.<ButtonData>;
			
			if ( layoutType == KeyboardCreator.KEYBOARD_ALL )
			{
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create(1), ButtonData.create(2), ButtonData.create(3), ButtonData.create(4), ButtonData.create(5), 
							 ButtonData.create(6), ButtonData.create(7), ButtonData.create(8), ButtonData.create(9), ButtonData.create(0) );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create("Q"), ButtonData.create("W"), ButtonData.create("E"), ButtonData.create("R"), ButtonData.create("T"), 
							 ButtonData.create("Y"), ButtonData.create("U"), ButtonData.create("I"), ButtonData.create("O"), ButtonData.create("P") );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create("A"), ButtonData.create("S"), ButtonData.create("D"), ButtonData.create("F"), ButtonData.create("G"), 
							 ButtonData.create("H"), ButtonData.create("J"), ButtonData.create("K"), ButtonData.create("L"), ButtonData.create(COMMAND_DELETE, "Delete") );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create("Z"), ButtonData.create("X"), ButtonData.create("C"), ButtonData.create("V"), ButtonData.create("B"), 
							 ButtonData.create("N"), ButtonData.create("M"), ButtonData.create(" ", COMMAND_SPACE), ButtonData.create(COMMAND_ENTER, "Enter", 2) );
				layout.push( keyRow );
			}
			if ( layoutType == KeyboardCreator.KEYBOARD_TEXT )
			{
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create("Q"), ButtonData.create("W"), ButtonData.create("E"), ButtonData.create("R"), ButtonData.create("T"), 
							 ButtonData.create("Y"), ButtonData.create("U"), ButtonData.create("I"), ButtonData.create("O"), ButtonData.create("P") );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create("A"), ButtonData.create("S"), ButtonData.create("D"), ButtonData.create("F"), ButtonData.create("G"), 
							 ButtonData.create("H"), ButtonData.create("J"), ButtonData.create("K"), ButtonData.create("L"), ButtonData.create(COMMAND_DELETE, "Delete") );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create("Z"), ButtonData.create("X"), ButtonData.create("C"), ButtonData.create("V"), ButtonData.create("B"), 
							 ButtonData.create("N"), ButtonData.create("M"), ButtonData.create(" ", COMMAND_SPACE), ButtonData.create(COMMAND_ENTER, "Enter", 2) );
				layout.push( keyRow );
			}
			else if ( layoutType == KeyboardCreator.KEYBOARD_NUMERIC )
			{
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create(7), ButtonData.create(8), ButtonData.create(9) );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create(4), ButtonData.create(5), ButtonData.create(6) );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create(1), ButtonData.create(2), ButtonData.create(3) );
				layout.push( keyRow );
				
				keyRow = new Vector.<ButtonData>();
				keyRow.push( ButtonData.create(0),  ButtonData.create(COMMAND_ENTER, "enter", 2) );
				layout.push( keyRow );
			}
			return layout;
		}
		
		public static const KEYBOARD_ALL:String 	= "numeric_text";
		public static const KEYBOARD_TEXT:String 	= "text";
		public static const KEYBOARD_NUMERIC:String = "numeric";
		
		public static const COMMAND_ENTER:String 	= "enter";
		public static const COMMAND_DELETE:String 	= "delete";
		public static const COMMAND_SPACE:String 	= "space";
		public static const COMMAND_BACK:String 	= "backspace";
		public static const COMMAND_FORWARD:String 	= "forwardspace";
	}
}
