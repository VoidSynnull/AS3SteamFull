package game.ui.costumizer {

public interface CostumizerDelegate {

	function shouldIncludeCloset():Boolean;
	function playerDidAcceptNewLook():void;
}

}
