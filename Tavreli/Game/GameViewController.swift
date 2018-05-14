//
//  GameViewController.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit
import RxSwift
import GameKit

class GameViewController: UIViewController {

    @IBOutlet weak var fieldCollectionView: UICollectionView!
    @IBOutlet weak var yourTurnLabel: UILabel!
    @IBOutlet weak var notYourTurnLabel: UILabel!
    @IBOutlet weak var towerLabel: UILabel!
    @IBOutlet weak var checkLabel: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var askForTieButton: UIButton!
    @IBOutlet weak var castlingButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let model = GameModel()
    
    fileprivate var chosenTavreliPiece: TavreliPiece! = nil
    fileprivate var towerMode: Bool = false

    fileprivate let localPlayerColor = PublishSubject<Color>()
    fileprivate let otherPlayerMove = PublishSubject<Move>()
    fileprivate let gameEndWithResult = PublishSubject<LocalResult>()
    fileprivate let askedForTie = PublishSubject<Void>()
    fileprivate var bag: DisposeBag = DisposeBag()
    
    fileprivate var moveMode: Bool = false {
        didSet {
            fieldCollectionView.allowsSelection = moveMode
            yourTurnLabel.isHidden = !moveMode
            notYourTurnLabel.isHidden = moveMode
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureFieldCollectionView()
        bindSelf()
        GameKitHelper.shared.gameIsLoading = true
        GameKitHelper.shared.authenticateLocalPlayer()
        
        clearButton.addTarget(self, action: #selector(clearChosenTavrel), for: .allTouchEvents)
        askForTieButton.addTarget(self, action: #selector(askForTie), for: .allTouchEvents)
        castlingButton.addTarget(self, action: #selector(castling), for: .allTouchEvents)
        
        activityIndicator.startAnimating()
    }

}

extension GameViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func configureFieldCollectionView() {
        fieldCollectionView.register(SquareCollectionViewCell.self)
        
        guard let layout = fieldCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        fieldCollectionView.delegate = self
        fieldCollectionView.dataSource = self
        
        fieldCollectionView.isScrollEnabled = false
        fieldCollectionView.showsVerticalScrollIndicator = false
        fieldCollectionView.showsHorizontalScrollIndicator = false
        fieldCollectionView.bounces = false
        fieldCollectionView.bouncesZoom = false
        fieldCollectionView.alwaysBounceHorizontal = false
        fieldCollectionView.alwaysBounceVertical = false
        fieldCollectionView.allowsSelection = false
        
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SquareCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

        return cell.configure(isWhite: (indexPath.item + indexPath.section) % 2 == 0,
                              piece: model.tavreli?[indexPath.section][indexPath.item])
    }
    
}

extension GameViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = collectionView.frame.width / 8
        return CGSize(width: side, height: side)
    }
    
}

private extension GameViewController {
    
    func bindSelf() {
        GameKitHelper.shared.presentAuthenticationViewController
            .bind { [weak self] in
                self?.present(GameKitHelper.shared.authenticationViewController,
                              animated: true, completion: nil)
            }
            .disposed(by: bag)
        
        GameKitHelper.shared.readyToStartGame
            .bind { [weak self] in
                guard let `self` = self else {
                    return
                }

                self.model.networkingEngine =
                    MultiplayerNetworking(localPlayerColor: self.localPlayerColor,
                                          otherPlayerMove: self.otherPlayerMove,
                                          gameEndWithResult: self.gameEndWithResult,
                                          askedForTie: self.askedForTie)
                GameKitHelper.shared.findMatch(viewController: self, delegate: self.model.networkingEngine,
                                               completion: { [weak self] in
                                                self?.activityIndicator.stopAnimating()
                                            })
            }
            .disposed(by: bag)
        
        fieldCollectionView.rx.itemSelected
            .bind { [weak self] indexPath in
                guard let `self` = self else {
                    return
                }
                
                if self.chosenTavreliPiece == nil {
                    self.chooseTavrel(at: indexPath)
                } else {
                    if self.chosenTavreliPiece.indexPath == indexPath && self.chosenTavreliPiece.z != 0 {
                        self.towerMode = true
                        (self.fieldCollectionView.cellForItem(at: indexPath) as? SquareCollectionViewCell)?.towerMode = true
                    } else if self.chosenTavreliPiece.isValidMove(to: indexPath, towerMode: self.towerMode, for: .local) {
                        self.moveChosenTavrel(to: indexPath)
                        self.checkForGameEnd(lastMoveTo: indexPath)
                    }
                }
            }
            .disposed(by: bag)
        
        localPlayerColor
            .bind { [weak self] color in
                self?.model.setupField(color: color)
                self?.moveMode = (color == .white)
                self?.fieldCollectionView.reloadData()
            }
            .disposed(by: bag)
        
        otherPlayerMove
            .bind { [weak self] in
                self?.addRemoteMove($0)
            }
            .disposed(by: bag)
        
        gameEndWithResult
            .bind { [weak self] localResult in
                self?.gameEnded(localResult: localResult)
            }
            .disposed(by: bag)
        
        askedForTie
            .bind { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                let alert = UIAlertController(title: "Хотите ничью?", message: nil, preferredStyle: .alert)
                let yes = UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
                    self?.endGame(with: .tie)
                })
                alert.addAction(yes)
                alert.addAction(UIAlertAction(title: "Нет", style: .destructive, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .disposed(by: bag)
    }
    
    func gameEnded(localResult: LocalResult) {
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "gameOverViewController")
            as? GameOverViewController {
            (UIApplication.shared.windows[0] as UIWindow).rootViewController = viewController
            switch localResult {
            case .localPlayerWon:
                viewController.label.text = "Вы выиграли"
            case .localPlayerLost:
                viewController.label.text = "Вы проиграли"
            case .tie:
                viewController.label.text = "Ничья"
            }
        }
    }

}

private extension GameViewController {
    
    @objc func clearChosenTavrel() {
        if chosenTavreliPiece != nil {
            (fieldCollectionView.cellForItem(at: chosenTavreliPiece.indexPath) as? SquareCollectionViewCell)?
                .isChosen = false
            (fieldCollectionView.cellForItem(at: chosenTavreliPiece.indexPath) as? SquareCollectionViewCell)?
                .towerMode = false
            chosenTavreliPiece = nil
            towerMode = false
            towerLabel.isHidden = true
        }
    }
    
    @objc func askForTie() {
        model.networkingEngine.sendAskForTie()
    }
    
    @objc func castling() {
        if moveMode && chosenTavreliPiece is Fighter {
            let oldIndexPath = chosenTavreliPiece.indexPath
            if model.performCastlingWithResult(with: chosenTavreliPiece as! Fighter) {
                afterMove(from: oldIndexPath)
                
                castlingButton.isHidden = true
            }
        }
    }
    
}

private extension GameViewController {
    
    func chooseTavrel(at indexPath: IndexPath) {
        if let tavrel = model.tavreli[indexPath.section][indexPath.item], tavrel.player == .local {
            chosenTavreliPiece = tavrel
            (self.fieldCollectionView.cellForItem(at: indexPath) as? SquareCollectionViewCell)?.isChosen = true
            if self.chosenTavreliPiece.z != 0 {
                self.towerLabel.isHidden = false
            }
            self.clearButton.isHidden = false
        }
    }
    
    func moveChosenTavrel(to indexPath: IndexPath) {
        let oldIndexPath = chosenTavreliPiece.indexPath
        model.moveTavrel(chosenTavreliPiece, to: indexPath, towerMode: towerMode)
        
        let move = Move(oldCoordinates: oldIndexPath, newCoordinates: indexPath, towerMode: towerMode)
        model.networkingEngine.sendMove(move)
        
        afterMove(from: oldIndexPath)
    }
    
    func afterMove(from indexPath: IndexPath) {
        fieldCollectionView.reloadData()
        
        if towerMode {
            (fieldCollectionView.cellForItem(at: indexPath) as? SquareCollectionViewCell)?.towerMode = false
        } else {
            (fieldCollectionView.cellForItem(at: indexPath) as? SquareCollectionViewCell)?.isChosen = false
        }
        
        moveMode = false
        chosenTavreliPiece = nil
        towerMode = false
        towerLabel.isHidden = true
        clearButton.isHidden = true
        
        notifyIfCheck()
    }
    
    func addRemoteMove(_ move: Move) {
        model.addMove(move)
        fieldCollectionView.reloadData()
        moveMode = true
        
        notifyIfCheck()
    }
    
}

private extension GameViewController {
    
    func notifyIfCheck() {
        checkLabel.isHidden = false
        if model.isCheck(for: .local) {
            checkLabel.text = "Вам поставили шах, спасайте волхва!"
        } else if model.isCheck(for: .remote) {
            checkLabel.text = "Вы поставили шах, атакуйте волхва!"
        } else {
            checkLabel.isHidden = true
        }
    }
    
    func checkForGameEnd(lastMoveTo: IndexPath) {
        if let eatenTavrel = model.lastEaten(lastMoveTo: lastMoveTo), eatenTavrel is Magus {
            endGame(with: eatenTavrel.player == .local ? .localPlayerLost : .localPlayerWon)
        } else if model.isPat() {
            endGame(with: .tie)
        }
    }
    
    private func endGame(with result: LocalResult) {
        model.networkingEngine.sendGameEnd(localResult: result)
        gameEnded(localResult: result)
    }
    
}
