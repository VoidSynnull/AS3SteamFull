package game.scenes.prison.metalShop.popups
{	
	import ash.core.Component;
	
	public class LicensePlate extends Component
	{
		public var targetText:String;
		private var inputText:Array;
		public var textPos:int = 0;
		public var plateFull:Boolean = false;
		
		public function LicensePlate()
		{
			inputText = [" "," "," "," "," "];
		}
		
		public function pushInputText(inputText:String):Boolean
		{
			if(!plateFull){
				if(textPos < this.inputText.length){
					this.inputText[textPos] = inputText;
					textPos++
					if(textPos == this.inputText.length){
						plateFull = true;
					}
					return true;
				}else{
					plateFull = true;
					return false;
				}
			}else{
				return false;
			}
		}
		
		public function getTextAt(index:int):String
		{
			if(index < inputText.length){
				return inputText[index];
			}
			else{
				return " ";
			}
		}

		public function resetInput():void
		{
			inputText.splice(0, inputText.length);
			inputText = [" "," "," "," "," "];
			textPos = 0;
			plateFull = false;
		}
		
		override public function destroy():void
		{
			targetText = "";
			inputText = null;
			super.destroy();	
		}
	}
}