package game.ui.inventory
{

	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import game.ui.elements.TabElement;
	import game.util.TextUtils;

	public class InventoryTab extends TabElement
	{

		public function InventoryTab( id:String = "", title:String = "")
		{
			super.id = id;
			super.title = title;
		}
		
		override public function init():void
		{
			// assign textfield
			var tf:TextField = MovieClip(super.displayObject).tabText.tf;
			tf = TextUtils.refreshText( tf );
			tf.embedFonts = true;
			tf.defaultTextFormat = new TextFormat("CreativeBlock BB", 37, 0xFFFFFF);
			tf.text = super.title;
			
			//set icon basd on id
			MovieClip(super.displayObject).icon.gotoAndStop(super.id);
		}
	}
}