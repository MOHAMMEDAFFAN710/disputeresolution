import { useState, useEffect } from "react";
import Web3 from "web3";
import { contractAddress, contractABI } from "../lib/contract";

export const useContract = () => {
  const [web3, setWeb3] = useState<any>(null);
  const [contract, setContract] = useState<any>(null);
  const [account, setAccount] = useState<string>("");
  const [items, setItems] = useState<any[]>([]);
  const [itemCount, setItemCount] = useState<number>(0);

  useEffect(() => {
    if (typeof window !== "undefined" && (window as any).ethereum) {
      const w3 = new Web3((window as any).ethereum);
      setWeb3(w3);

      (async () => {
        const accounts = await w3.eth.requestAccounts();
        setAccount(accounts[0]);

        const c = new w3.eth.Contract(contractABI as any, contractAddress);
        setContract(c);
      })();
    }
  }, []);

  useEffect(() => {
    if (contract) {
      loadItems();

      contract.events.ItemAdded().on("data", loadItems);
      contract.events.ItemUpdated().on("data", loadItems);
    }
  }, [contract]);

  const loadItems = async () => {
    if (!contract) return;

    const count = await contract.methods.itemCount().call();
    setItemCount(Number(count));

    let list: any[] = [];
    for (let i = 1; i <= Number(count); i++) {
      try {
        const item = await contract.methods.getItem(i).call();
        list.push({ id: i, name: item[0], quantity: Number(item[1]) });
      } catch {}
    }
    setItems(list);
  };

  const addItem = async (name: string, quantity: number) => {
    await contract.methods.addItem(name, quantity).send({ from: account });
  };

  const updateQuantity = async (itemId: number, qty: number) => {
    await contract.methods.updateQuantity(itemId, qty).send({ from: account });
  };

  return {
    account,
    items,
    itemCount,
    addItem,
    updateQuantity,
  };
};
